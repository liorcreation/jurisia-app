# JurisIA

Assistant juridique IA multiplateforme (Flutter) pour le Burkina Faso, en 5
modules : Litiges et consultations, Bibliothèque juridique, Espace étudiant,
Espace professionnel, Contacter un professionnel.

## Architecture

- Chaque module suit une Clean Architecture (`domain` / `data` /
  `presentation`) sous `lib/features/`.
- Persistance et authentification : Supabase (voir `server/supabase/`).
- Abonnements : `lib/core/entitlements/` (catalogue d'offres, quotas, porte
  d'accès + feuille d'incitation, écran « Mon abonnement »). Le serveur
  (`plans` / `usage_counters` / RPC, migration 007) fait foi quand il
  répond ; sinon un compteur mensuel local applique le quota Découverte.
- Paiement : Edge Functions `supabase/functions/billing-checkout` /
  `billing-webhook` + `lib/core/billing/`. Prestataire enfichable
  (`BILLING_PROVIDER` = `mock` par défaut, ou `cinetpay` pour le Mobile
  Money). Un abonnement ne s'active que par un paiement confirmé
  (`payment_intents`, migration 009).
- IA : Groq, jamais appelé directement depuis le client — toujours via le
  relais Cloudflare Worker (voir `server/groq-proxy/`), qui détient la clé
  API et applique validation, CORS et limitation de débit. Le relais
  reconnaît le jeton Supabase de l'appelant (rétrocompatible) et applique
  alors les quotas d'IA de son abonnement.
- Console d'administration : application web **séparée**, point d'entrée
  `lib/admin_main.dart`, code sous `lib/admin/`. Même projet Supabase,
  design system partagé (accent cobalt), jamais dans le bundle grand public.
  Accès filtré par un rôle de personnel (`staff_roles`, migration 006).

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

### Console d'administration (web séparé)

Point d'entrée distinct, à compiler et déployer comme un projet Cloudflare
Pages à part (sur sa propre origine) :

```
flutter run  -d chrome -t lib/admin_main.dart
flutter build web -t lib/admin_main.dart
npx wrangler pages deploy build/web --project-name=jurisia-admin
```

Prérequis : exécuter `server/supabase/migration_006` … `008`, puis créer le
premier compte `super_admin` en insérant sa ligne dans `staff_roles`
(SQL Editor). Un compte sans rôle voit un écran « Accès refusé ».

### Paiement (Edge Functions Supabase)

```
supabase secrets set --env-file supabase/functions/.env --project-ref <ref>
supabase functions deploy billing-checkout --project-ref <ref>
supabase functions deploy billing-webhook  --project-ref <ref>
```

Prérequis : `server/supabase/migration_009`. Détails, choix du prestataire
et test local : `supabase/functions/README.md`. Avec `BILLING_PROVIDER=mock`
(défaut), le parcours complet (bouton → abonnement actif) fonctionne sans
compte prestataire.

### Mobile (Android / iOS)

Pas encore publié sur le Play Store ni l'App Store — seuls des builds de
debug ont été testés (`flutter build apk --debug`). La compilation iOS
nécessite un Mac, indisponible dans cet environnement de développement.

### Backend

Voir `server/groq-proxy/README.md` (relais Groq, Cloudflare Worker) et
`server/supabase/` (schéma et migrations SQL, à exécuter manuellement dans
l'éditeur SQL du tableau de bord Supabase).
