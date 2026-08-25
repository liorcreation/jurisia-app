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

## Sécurité — ce que ce relais protège, et ce qu'il ne protège pas

Protégé : la clé Groq elle-même n'est plus jamais présente dans le binaire de
l'application ni dans ses requêtes réseau.

Pas protégé (volontairement hors périmètre de cette étape) : ce Worker
n'authentifie pas l'appelant. Tant qu'aucun compte utilisateur n'existe côté
application, quiconque connaît cette URL peut l'appeler et consommer votre
quota Groq. Deux mitigations recommandées en attendant l'authentification
réelle (item séparé de la feuille de route) :

- Activer une règle de limitation de débit dans le tableau de bord
  Cloudflare : **Security → WAF → Rate limiting rules** (quelques clics,
  aucun code à écrire).
- Surveiller votre consommation sur https://console.groq.com/ et régénérer
  la clé (`wrangler secret put GROQ_API_KEY` avec une nouvelle valeur) en cas
  d'usage anormal.

## Redéployer après une modification de `src/index.js`

```
npx wrangler deploy
```
