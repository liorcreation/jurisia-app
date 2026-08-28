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

## Authentification de l'appelant et quotas par abonnement

Le Worker reconnaît un en-tête `Authorization: Bearer <jwt Supabase>` :

- **avec un jeton valide** : il valide le jeton auprès de Supabase
  (`/auth/v1/user`), lit l'offre de l'utilisateur (`jurisia_plan_code`,
  migration 007) et applique les quotas et le plafond de jetons de son
  palier (`TIER_LIMITS` dans `src/index.js`, à tenir aligné avec la table
  `ai_limits`). La limitation de débit se fait alors **par utilisateur**
  (`user:<id>`) et non plus par IP ;
- **sans jeton, ou si la validation échoue** : le Worker retombe
  **exactement** sur son comportement historique (limites `ANON_LIMITS` par
  IP). Aucune coupure de service — la bascule est sans risque.

Cela nécessite les variables `SUPABASE_URL` et `SUPABASE_ANON_KEY` dans
`wrangler.toml` (déjà renseignées ; ce ne sont pas des secrets). Sans elles,
le Worker ignore les jetons et limite par IP.

Côté client Flutter, `lib/core/ai/groq_providers.dart` joint automatiquement
le jeton de la session Supabase courante.

## Sécurité — ce que ce relais protège, et ce qu'il ne protège pas

Protégé : la clé Groq elle-même n'est plus jamais présente dans le binaire de
l'application ni dans ses requêtes réseau. Les bornes ci-dessus limitent
l'exposition financière et l'abus grossier (script, boucle).

Partiellement protégé : depuis un jeton Supabase, la limitation se fait par
compte et par palier d'abonnement (voir la section « Authentification de
l'appelant » ci-dessus). Mais un appelant qui n'envoie pas de jeton reste
limité par IP uniquement, et les compteurs KV ne sont pas parfaitement
atomiques (voir le commentaire en tête de `src/index.js`) : une limitation
exacte demanderait un Durable Object. En complément, vous pouvez activer une
règle de limitation de débit native dans le tableau de bord Cloudflare
(**Security → WAF → Rate limiting rules**) et surveiller votre consommation
sur https://console.groq.com/.

## Supervision en production (logs, métriques, alerting)

Le Worker journalise chaque requête en JSON structuré (`console.log`), sans
jamais logger le contenu des messages : `completed` (modèle, statut HTTP,
durée), `rate_limited`, `rejected` (avec la raison : corps trop volumineux,
JSON invalide, validation), `upstream_error`, `misconfigured`.

- **Logs en direct** :
  ```
  npx wrangler tail
  ```
- **Logs persistés et filtrables** (quelques jours de rétention) : activés
  via `[observability] enabled = true` dans `wrangler.toml`, consultables
  dans le tableau de bord Cloudflare → Workers & Pages → `jurisia-groq-proxy`
  → onglet **Logs**.
- **Métriques** (requêtes, erreurs, latence, CPU) : onglet **Metrics** du
  même tableau de bord, sans configuration supplémentaire.
- **Alerting** (étape manuelle, une seule fois, non scriptable via
  `wrangler`) : tableau de bord Cloudflare → **Notifications** → *Add* →
  chercher le type d'alerte **Workers** (ex. taux d'erreur, quantité de
  requêtes) → sélectionner `jurisia-groq-proxy` → indiquer un e-mail. C'est
  la façon d'être prévenu d'un pic d'erreurs sans avoir à surveiller le
  tableau de bord activement.

Côté Supabase, l'authentification, l'API REST et la base disposent déjà de
leurs propres journaux dans le tableau de bord Supabase (**Logs** dans le
menu du projet) — aucune configuration supplémentaire n'est nécessaire.

## Redéployer après une modification de `src/index.js` ou `wrangler.toml`

```
npx wrangler deploy
```
