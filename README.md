# JurisIA

Assistant juridique IA multiplateforme (Flutter) pour le Burkina Faso, en 5
modules : Litiges et consultations, Bibliothèque juridique, Espace étudiant,
Espace professionnel, Contacter un professionnel.

## Architecture

- Chaque module suit une Clean Architecture (`domain` / `data` /
  `presentation`) sous `lib/features/`.
- Persistance et authentification : Supabase (voir `server/supabase/`).
- IA : Groq, jamais appelé directement depuis le client — toujours via le
  relais Cloudflare Worker (voir `server/groq-proxy/`), qui détient la clé
  API et applique validation, CORS et limitation de débit.

## Développement local

```
flutter pub get
flutter run -d chrome    # ou -d windows, -d <device Android>
```

Qualité :

```
flutter analyze
flutter test
```

## Déploiement

### Web (Cloudflare Pages)

L'app web est en ligne sur **https://jurisia-app.pages.dev** (Cloudflare
Pages, gratuit). Pour publier une nouvelle version après des changements :

```
flutter build web --release
npx wrangler pages deploy build/web --project-name=jurisia-app
```

Chaque déploiement obtient aussi sa propre URL de prévisualisation
(`https://<hash>.jurisia-app.pages.dev`) — les deux formes sont déjà
autorisées dans la liste CORS du Worker (`server/groq-proxy/src/index.js`,
`ALLOWED_ORIGIN_PATTERNS`). Si l'app est un jour servie depuis un autre
domaine (domaine personnalisé, etc.), il faut l'ajouter à cette liste et
redéployer le Worker (`npx wrangler deploy` depuis `server/groq-proxy/`),
sinon le navigateur se fera bloquer par CORS en appelant l'IA.

### Mobile (Android / iOS)

Pas encore publié sur le Play Store ni l'App Store — seuls des builds de
debug ont été testés (`flutter build apk --debug`). La compilation iOS
nécessite un Mac, indisponible dans cet environnement de développement.

### Backend

Voir `server/groq-proxy/README.md` (relais Groq, Cloudflare Worker) et
`server/supabase/` (schéma et migrations SQL, à exécuter manuellement dans
l'éditeur SQL du tableau de bord Supabase).
