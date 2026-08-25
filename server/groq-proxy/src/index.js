/**
 * Relais JurisIA vers l'API Groq.
 *
 * Le seul rôle de ce Worker : détenir la clé Groq côté serveur et relayer
 * fidèlement les requêtes de complétion (y compris le streaming SSE), pour
 * que la clé ne soit plus jamais embarquée dans le client Flutter (binaire,
 * requêtes réseau, build Web).
 *
 * Ce Worker N'EST PAS une couche d'authentification : tant qu'aucun compte
 * utilisateur n'existe côté app (voir la feuille de route), n'importe qui
 * connaissant cette URL peut l'appeler et consommer le quota Groq. Active au
 * minimum une règle de rate limiting Cloudflare (tableau de bord > Security >
 * WAF > Rate limiting rules) en attendant l'authentification réelle.
 */

const GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

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
      return new Response('Proxy misconfigured: missing GROQ_API_KEY secret', {
        status: 500,
        headers: CORS_HEADERS,
      });
    }

    const body = await request.text();

    let groqResponse;
    try {
      groqResponse = await fetch(GROQ_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${env.GROQ_API_KEY}`,
        },
        body,
      });
    } catch (error) {
      return new Response(`Upstream error: ${error}`, { status: 502, headers: CORS_HEADERS });
    }

    // Le corps de la réponse Groq (flux SSE inclus) est relayé tel quel, sans
    // mise en mémoire tampon, pour préserver le streaming côté client.
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
