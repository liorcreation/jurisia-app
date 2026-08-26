# Relais JurisIA vers Groq

Cloudflare Worker qui détient la clé API Groq côté serveur, pour qu'elle ne
soit plus jamais embarquée dans l'application Flutter. Le Worker relaie
fidèlement les requêtes de complétion vers Groq, streaming SSE compris.

## Déploiement (à faire une seule fois, depuis ce dossier)

1. Installer les dépendances :
   ```
   npm install
   ```

2. Se connecter à votre compte Cloudflare (ouvre une fenêtre de navigateur) :
   ```
   npx wrangler login
   ```

3. Enregistrer la clé Groq comme secret Cloudflare (elle n'est jamais écrite
   dans un fichier du dépôt) :
   ```
   npx wrangler secret put GROQ_API_KEY
   ```
   Collez votre clé (`gsk_...`, obtenue sur https://console.groq.com/keys)
   quand c'est demandé.

4. Déployer :
   ```
   npx wrangler deploy
   ```
   La commande affiche l'URL du Worker, de la forme
   `https://jurisia-groq-proxy.<votre-sous-domaine>.workers.dev`.

5. Donnez cette URL pour qu'elle soit configurée côté application Flutter
   (`GroqApiConfig.endpoint`) — c'est une URL publique, pas un secret, elle
   peut être commitée sans risque.

## Limitation de débit (anti-abus) — mise en place du namespace KV

Le Worker limite désormais le débit par adresse IP (20 requêtes/minute,
300/jour) via un compteur stocké dans Cloudflare KV. Sans cette étape, le
Worker continue de fonctionner normalement mais sans limiter le débit.

1. Créer le namespace (une seule fois) :
   ```
   npx wrangler kv namespace create RATE_LIMIT_KV
   ```
   La commande affiche un `id`.

2. Remplacer `REMPLACER_APRES_wrangler_kv_namespace_create` dans
   `wrangler.toml` par cet `id`.

3. Redéployer (voir plus bas).

## Validation et bornes appliquées par le Worker

En plus de relayer la requête, le Worker rejette désormais :

- un modèle autre que celui explicitement autorisé (`ALLOWED_MODELS` dans
  `src/index.js` — à tenir synchronisé avec `GROQ_MODEL` côté client si vous
  en changez) ;
- un corps de requête de plus de 60 Ko, ou un contenu de messages cumulé de
  plus de 24 000 caractères ;
- un `max_tokens` supérieur à 4096, quoi que le client demande (borne appliquée
  silencieusement, pas un rejet) ;
- plus de 20 requêtes/minute ou 300/jour pour une même adresse IP (nécessite
  le namespace KV ci-dessus).

## Sécurité — ce que ce relais protège, et ce qu'il ne protège pas

Protégé : la clé Groq elle-même n'est plus jamais présente dans le binaire de
l'application ni dans ses requêtes réseau. Les bornes ci-dessus limitent
l'exposition financière et l'abus grossier (script, boucle).

Pas protégé (volontairement hors périmètre de cette étape) : ce Worker
n'authentifie toujours pas l'appelant — la limitation de débit se fait par IP,
pas par compte utilisateur, et les compteurs KV ne sont pas parfaitement
atomiques (voir le commentaire en tête de `src/index.js`). Une vraie
authentification par utilisateur au niveau du Worker reste l'item séparé de
la feuille de route (« authentification & comptes »). En complément, vous
pouvez toujours activer une règle de limitation de débit native dans le
tableau de bord Cloudflare (**Security → WAF → Rate limiting rules**) et
surveiller votre consommation sur https://console.groq.com/.

## Redéployer après une modification de `src/index.js` ou `wrangler.toml`

```
npx wrangler deploy
```
