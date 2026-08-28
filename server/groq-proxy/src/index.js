/**
 * Relais JurisIA vers l'API Groq.
 *
 * Le rôle de ce Worker : détenir la clé Groq côté serveur, valider et
 * borner ce qui lui est soumis avant de le relayer (streaming SSE compris),
 * et limiter le débit — par utilisateur connecté quand un jeton Supabase est
 * fourni, sinon par adresse IP — pour contenir l'exposition financière en
 * cas d'abus.
 *
 * Authentification de l'appelant (rétrocompatible) : si la requête porte un
 * en-tête `Authorization: Bearer <jwt Supabase>`, le Worker valide le jeton
 * auprès de Supabase, lit l'offre de l'utilisateur (`jurisia_plan_code`) et
 * applique les quotas et le plafond de jetons de son palier (voir
 * `TIER_LIMITS`, à tenir aligné avec la table `ai_limits` de
 * `server/supabase/migration_007_subscriptions_and_usage.sql`). En l'absence
 * de jeton, ou si sa validation échoue, le Worker retombe **exactement** sur
 * son comportement historique (limites par IP) : aucune coupure de service.
 *
 * Limite de la limitation de débit : les compteurs vivent dans Cloudflare
 * KV, qui n'est PAS fortement cohérent ni atomique — deux requêtes
 * concurrentes depuis la même identité peuvent, dans une fenêtre de
 * quelques dizaines de millisecondes, toutes deux lire l'ancien compteur.
 * C'est un frein sérieux contre un abus grossier (script, boucle), pas une
 * garantie cryptographique — une limitation exacte demanderait un Durable
 * Object.
 */

const GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';

// Origines navigateur autorisées à appeler ce Worker depuis du JavaScript
// (fetch/XHR). Ne concerne QUE les clients navigateur : les apps Flutter
// mobile/desktop natives n'envoient pas d'en-tête Origin et ne sont donc
// jamais concernées par cette liste.
const ALLOWED_ORIGIN_PATTERNS = [
  /^https?:\/\/localhost(:\d+)?$/,
  /^https?:\/\/127\.0\.0\.1(:\d+)?$/,
  // App web JurisIA sur Cloudflare Pages : le domaine de production
  // (jurisia-app.pages.dev) et chaque déploiement de prévisualisation
  // (<hash>.jurisia-app.pages.dev), tous deux servant le même build.
  /^https:\/\/([a-z0-9-]+\.)?jurisia-app\.pages\.dev$/,
];

function isAllowedOrigin(origin) {
  return ALLOWED_ORIGIN_PATTERNS.some((pattern) => pattern.test(origin));
}

// Construit les en-têtes CORS pour cette requête précise : `origin` est déjà
// vérifié appartenir à la liste autorisée (ou est `null` pour un appel non-
// navigateur), donc le refléter tel quel est sûr — contrairement à un `*`
// statique, qui autoriserait n'importe quel site tiers à faire consommer le
// quota Groq via le navigateur de ses visiteurs.
function corsHeadersFor(origin) {
  const headers = {
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    Vary: 'Origin',
  };
  if (origin) {
    headers['Access-Control-Allow-Origin'] = origin;
  }
  return headers;
}

// Doit rester synchronisé avec lib/core/ai/groq_api_config.dart côté client
// (GROQ_MODEL) : la liste des modèles qu'un appelant est autorisé à
// demander, pour qu'un client modifié ne puisse pas faire consommer la clé
// sur un modèle plus coûteux.
const ALLOWED_MODELS = ['openai/gpt-oss-120b'];

const MAX_BODY_BYTES = 60_000; // généreux pour un contrat long, borne l'abus
const MAX_MESSAGES_CHARS = 24_000;
const MAX_TOKENS_CEILING = 4096; // plafond absolu, quel que soit le palier

const RATE_LIMIT_WINDOW_SECONDS = 60;

// Limites appliquées à un appelant NON authentifié (comportement historique).
const ANON_LIMITS = {
  reqPerMinute: 20,
  reqPerDay: 300,
  maxTokens: MAX_TOKENS_CEILING,
};

// Limites par palier d'abonnement — à tenir aligné avec la table `ai_limits`
// de migration_007. Un palier inconnu retombe sur `decouverte`.
const TIER_LIMITS = {
  decouverte: { reqPerMinute: 12, reqPerDay: 150, maxTokens: 1536 },
  plus: { reqPerMinute: 30, reqPerDay: 600, maxTokens: 2048 },
  etudiant: { reqPerMinute: 20, reqPerDay: 400, maxTokens: 1536 },
  pro: { reqPerMinute: 60, reqPerDay: 2000, maxTokens: 3072 },
  cabinet: { reqPerMinute: 60, reqPerDay: 2000, maxTokens: 3072 },
};

function limitsForPlan(plan) {
  return TIER_LIMITS[plan] || TIER_LIMITS.decouverte;
}

function jsonError(message, status, corsHeaders) {
  return new Response(JSON.stringify({ error: { message } }), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// Journal structuré (jamais le contenu des messages : voir la défense
// anti-injection dans le client, ce Worker suit la même discipline) capté
// par Workers Logs pour la supervision en production — dashboard Cloudflare
// > Workers & Pages > jurisia-groq-proxy > Logs.
function logEvent(event, fields) {
  console.log(JSON.stringify({ event, ts: new Date().toISOString(), ...fields }));
}

/**
 * Résout l'appelant. Rétrocompatible : sans jeton, ou en cas d'échec de
 * validation, renvoie `{ authenticated: false }` — le Worker se comporte
 * alors exactement comme avant (limites par IP).
 */
async function resolveCaller(request, env) {
  const auth = request.headers.get('Authorization') || '';
  if (!auth.startsWith('Bearer ')) return { authenticated: false };
  if (!env.SUPABASE_URL || !env.SUPABASE_ANON_KEY) return { authenticated: false };

  const token = auth.slice('Bearer '.length).trim();
  if (!token) return { authenticated: false };

  try {
    const userRes = await fetch(`${env.SUPABASE_URL}/auth/v1/user`, {
      headers: { Authorization: `Bearer ${token}`, apikey: env.SUPABASE_ANON_KEY },
    });
    if (!userRes.ok) return { authenticated: false };
    const user = await userRes.json();
    if (!user || !user.id) return { authenticated: false };

    let plan = 'decouverte';
    try {
      const planRes = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/jurisia_plan_code`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          apikey: env.SUPABASE_ANON_KEY,
          'Content-Type': 'application/json',
        },
        body: '{}',
      });
      if (planRes.ok) {
        const raw = await planRes.json();
        if (typeof raw === 'string' && raw) plan = raw;
      }
    } catch (error) {
      // La migration 007 n'est peut-être pas encore appliquée : on garde
      // 'decouverte', sans échouer.
    }

    return { authenticated: true, userId: user.id, plan };
  } catch (error) {
    return { authenticated: false };
  }
}

async function checkRateLimit(env, identity, limits) {
  if (!env.RATE_LIMIT_KV) {
    // Pas de namespace KV lié : on n'échoue pas fermé, on n'échoue pas
    // ouvert silencieusement non plus — voir le README pour le lier.
    return { allowed: true };
  }

  const now = Math.floor(Date.now() / 1000);
  const minuteKey = `rl:min:${identity}:${Math.floor(now / RATE_LIMIT_WINDOW_SECONDS)}`;
  const dayKey = `rl:day:${identity}:${Math.floor(now / 86400)}`;

  const [minuteCountRaw, dayCountRaw] = await Promise.all([
    env.RATE_LIMIT_KV.get(minuteKey),
    env.RATE_LIMIT_KV.get(dayKey),
  ]);
  const minuteCount = parseInt(minuteCountRaw || '0', 10);
  const dayCount = parseInt(dayCountRaw || '0', 10);

  if (minuteCount >= limits.reqPerMinute) {
    return { allowed: false, reason: 'Trop de requêtes cette minute, réessayez dans un instant.' };
  }
  if (dayCount >= limits.reqPerDay) {
    return { allowed: false, reason: 'Quota quotidien atteint, réessayez demain ou passez à une offre supérieure.' };
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
    const requestOrigin = request.headers.get('Origin');
    // Absent d'en-tête Origin = client non-navigateur (app mobile/desktop
    // native) : jamais concerné par CORS, toujours accepté ici. Présent mais
    // hors liste = page web tierce essayant d'utiliser le quota Groq via le
    // navigateur d'un visiteur : rejeté avant même d'atteindre Groq.
    if (requestOrigin && !isAllowedOrigin(requestOrigin)) {
      logEvent('rejected', { reason: 'origin_not_allowed', origin: requestOrigin });
      return jsonError('Origin non autorisée.', 403, corsHeadersFor(null));
    }
    const cors = corsHeadersFor(requestOrigin);

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: cors });
    }

    const url = new URL(request.url);
    if (url.pathname !== '/v1/chat/completions') {
      return new Response('Not found', { status: 404, headers: cors });
    }
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405, headers: cors });
    }
    if (!env.GROQ_API_KEY) {
      logEvent('misconfigured', {});
      return jsonError('Proxy misconfigured: missing GROQ_API_KEY secret', 500, cors);
    }

    const started = Date.now();
    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

    // Identité de l'appelant : par utilisateur si un jeton Supabase valide
    // est fourni, sinon par IP (comportement historique).
    const caller = await resolveCaller(request, env);
    const limits = caller.authenticated ? limitsForPlan(caller.plan) : ANON_LIMITS;
    const identity = caller.authenticated ? `user:${caller.userId}` : `ip:${ip}`;

    const rateLimit = await checkRateLimit(env, identity, limits);
    if (!rateLimit.allowed) {
      logEvent('rate_limited', {
        identity,
        authenticated: caller.authenticated,
        plan: caller.authenticated ? caller.plan : null,
      });
      return jsonError(rateLimit.reason, 429, cors);
    }

    const rawBody = await request.text();
    if (new TextEncoder().encode(rawBody).length > MAX_BODY_BYTES) {
      logEvent('rejected', { identity, reason: 'body_too_large' });
      return jsonError(`Requête trop volumineuse (maximum ${MAX_BODY_BYTES} octets).`, 413, cors);
    }

    let parsed;
    try {
      parsed = JSON.parse(rawBody);
    } catch (error) {
      logEvent('rejected', { identity, reason: 'invalid_json' });
      return jsonError('Corps de requête JSON invalide.', 400, cors);
    }

    const validationError = validatePayload(parsed);
    if (validationError) {
      logEvent('rejected', { identity, reason: 'validation_failed' });
      return jsonError(validationError, 400, cors);
    }

    // Le plafond de tokens est borné côté serveur au plus petit de : ce que
    // demande le client, la limite du palier, et le plafond absolu. Un
    // client modifié ne peut pas faire générer (et facturer) des réponses
    // plus longues que ne l'autorise l'abonnement.
    parsed.max_tokens = Math.min(
      parsed.max_tokens ?? limits.maxTokens,
      limits.maxTokens,
      MAX_TOKENS_CEILING,
    );

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
      logEvent('upstream_error', { identity, model: parsed.model, error: String(error) });
      return jsonError(`Upstream error: ${error}`, 502, cors);
    }

    logEvent('completed', {
      identity,
      authenticated: caller.authenticated,
      plan: caller.authenticated ? caller.plan : null,
      model: parsed.model,
      status: groqResponse.status,
      durationMs: Date.now() - started,
    });

    // Le corps de la réponse Groq (flux SSE inclus) est relayé tel quel,
    // sans mise en mémoire tampon, pour préserver le streaming côté client.
    const responseHeaders = new Headers(groqResponse.headers);
    for (const [key, value] of Object.entries(cors)) {
      responseHeaders.set(key, value);
    }

    return new Response(groqResponse.body, {
      status: groqResponse.status,
      headers: responseHeaders,
    });
  },
};
