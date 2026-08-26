/**
 * Relais JurisIA vers l'API Groq.
 *
 * Le rôle de ce Worker : détenir la clé Groq côté serveur, valider et
 * borner ce qui lui est soumis avant de le relayer (streaming SSE compris),
 * et limiter le débit par adresse IP pour contenir l'exposition financière
 * en cas d'abus — puisque n'importe qui connaissant cette URL peut
 * l'appeler tant qu'aucune authentification par utilisateur n'existe côté
 * Worker (voir la feuille de route : « authentification & comptes »).
 *
 * Limite de la limitation de débit : les compteurs vivent dans Cloudflare
 * KV, qui n'est PAS fortement cohérent ni atomique — deux requêtes
 * concurrentes depuis la même IP peuvent, dans une fenêtre de quelques
 * dizaines de millisecondes, toutes deux lire l'ancien compteur avant que
 * l'une des deux écritures ne se propage. C'est un frein sérieux contre un
 * abus grossier (script, boucle), pas une garantie cryptographique — une
 * limitation exacte demanderait un Durable Object.
 */

const GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

// Doit rester synchronisé avec lib/core/ai/groq_api_config.dart côté client
// (GROQ_MODEL) : la liste des modèles qu'un appelant est autorisé à
// demander, pour qu'un client modifié ne puisse pas faire consommer la clé
// sur un modèle plus coûteux.
const ALLOWED_MODELS = ['openai/gpt-oss-120b'];

const MAX_BODY_BYTES = 60_000; // généreux pour un contrat long, borne l'abus
const MAX_MESSAGES_CHARS = 24_000;
const MAX_TOKENS_CEILING = 4096;

const RATE_LIMIT_WINDOW_SECONDS = 60;
const RATE_LIMIT_MAX_PER_MINUTE = 20;
const RATE_LIMIT_MAX_PER_DAY = 300;

function jsonError(message, status) {
  return new Response(JSON.stringify({ error: { message } }), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

async function checkRateLimit(env, ip) {
  if (!env.RATE_LIMIT_KV) {
    // Pas de namespace KV lié : on n'échoue pas fermé, on n'échoue pas
    // ouvert silencieusement non plus — voir le README pour le lier.
    return { allowed: true };
  }

  const now = Math.floor(Date.now() / 1000);
  const minuteKey = `rl:min:${ip}:${Math.floor(now / RATE_LIMIT_WINDOW_SECONDS)}`;
  const dayKey = `rl:day:${ip}:${Math.floor(now / 86400)}`;

  const [minuteCountRaw, dayCountRaw] = await Promise.all([
    env.RATE_LIMIT_KV.get(minuteKey),
    env.RATE_LIMIT_KV.get(dayKey),
  ]);
  const minuteCount = parseInt(minuteCountRaw || '0', 10);
  const dayCount = parseInt(dayCountRaw || '0', 10);

  if (minuteCount >= RATE_LIMIT_MAX_PER_MINUTE) {
    return { allowed: false, reason: 'Trop de requêtes cette minute, réessayez dans un instant.' };
  }
  if (dayCount >= RATE_LIMIT_MAX_PER_DAY) {
    return { allowed: false, reason: 'Quota quotidien atteint pour cette adresse, réessayez demain.' };
  }

  await Promise.all([
    env.RATE_LIMIT_KV.put(minuteKey, String(minuteCount + 1), {
      expirationTtl: RATE_LIMIT_WINDOW_SECONDS + 10,
    }),
    env.RATE_LIMIT_KV.put(dayKey, String(dayCount + 1), { expirationTtl: 86_400 + 10 }),
  ]);
  return { allowed: true };
}

function validatePayload(parsed) {
  if (typeof parsed !== 'object' || parsed === null) {
    return 'Corps de requête invalide.';
  }
  if (!ALLOWED_MODELS.includes(parsed.model)) {
    return `Modèle non autorisé : ${parsed.model}`;
  }
  if (!Array.isArray(parsed.messages) || parsed.messages.length === 0) {
    return 'Le champ "messages" doit être un tableau non vide.';
  }

  let totalChars = 0;
  for (const message of parsed.messages) {
    if (typeof message?.content !== 'string' || typeof message?.role !== 'string') {
      return 'Chaque message doit avoir "role" et "content" en chaîne de caractères.';
    }
    totalChars += message.content.length;
  }
  if (totalChars > MAX_MESSAGES_CHARS) {
    return `Contenu trop long (${totalChars} caractères, maximum ${MAX_MESSAGES_CHARS}).`;
  }

  return null;
}

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    const url = new URL(request.url);
    if (url.pathname !== '/v1/chat/completions') {
      return new Response('Not found', { status: 404, headers: CORS_HEADERS });
    }
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405, headers: CORS_HEADERS });
    }
    if (!env.GROQ_API_KEY) {
      return jsonError('Proxy misconfigured: missing GROQ_API_KEY secret', 500);
    }

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    const rateLimit = await checkRateLimit(env, ip);
    if (!rateLimit.allowed) {
      return jsonError(rateLimit.reason, 429);
    }

    const rawBody = await request.text();
    if (new TextEncoder().encode(rawBody).length > MAX_BODY_BYTES) {
      return jsonError(`Requête trop volumineuse (maximum ${MAX_BODY_BYTES} octets).`, 413);
    }

    let parsed;
    try {
      parsed = JSON.parse(rawBody);
    } catch (error) {
      return jsonError('Corps de requête JSON invalide.', 400);
    }

    const validationError = validatePayload(parsed);
    if (validationError) {
      return jsonError(validationError, 400);
    }

    // Le plafond de tokens demandé est borné côté serveur, quoi que le
    // client envoie : un client modifié ne peut pas faire générer (et
    // facturer) des réponses arbitrairement longues.
    parsed.max_tokens = Math.min(parsed.max_tokens ?? MAX_TOKENS_CEILING, MAX_TOKENS_CEILING);

    let groqResponse;
    try {
      groqResponse = await fetch(GROQ_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${env.GROQ_API_KEY}`,
        },
        body: JSON.stringify(parsed),
      });
    } catch (error) {
      return jsonError(`Upstream error: ${error}`, 502);
    }

    // Le corps de la réponse Groq (flux SSE inclus) est relayé tel quel,
    // sans mise en mémoire tampon, pour préserver le streaming côté client.
    const responseHeaders = new Headers(groqResponse.headers);
    for (const [key, value] of Object.entries(CORS_HEADERS)) {
      responseHeaders.set(key, value);
    }

    return new Response(groqResponse.body, {
      status: groqResponse.status,
      headers: responseHeaders,
    });
  },
};
