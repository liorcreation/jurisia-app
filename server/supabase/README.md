# Supabase — comptes et persistance JurisIA

## Mise en place (à faire une seule fois)

1. Créez un compte et un projet sur https://supabase.com (niveau gratuit
   suffisant pour démarrer).
2. Dans **Project Settings → Data API**, notez :
   - l'**URL du projet** (`https://xxxxx.supabase.co`)
   - la **clé publique** (« anon » / « publishable key »)

   Ces deux valeurs ne sont **pas des secrets** : Supabase est conçu pour
   qu'elles soient embarquées dans l'application, y compris la version Web.
   La sécurité réelle vient des politiques Row Level Security ci-dessous —
   ne cherchez jamais à les cacher comme la clé Groq.

3. Ouvrez **SQL Editor → New query**, collez le contenu de `schema.sql`, et
   exécutez-le. Il crée les tables (profils, consultations, favoris,
   progression étudiante, documents professionnels) avec la sécurité au
   niveau des lignes déjà activée sur chacune.

4. Dans **Authentication → Providers**, l'e-mail/mot de passe est activé par
   défaut — rien à faire pour démarrer. Vous pouvez désactiver la
   confirmation par e-mail (**Authentication → Settings**) pendant le
   développement, pour tester sans avoir à cliquer un lien de confirmation.

5. Donnez l'URL du projet et la clé publique pour que l'application soit
   configurée : elles se passent via
   `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
   (voir `lib/core/supabase/supabase_config.dart`).

## Ce que couvre le schéma actuel

- `profiles` — une ligne par utilisateur, créée automatiquement à
  l'inscription (déclencheur `on_auth_user_created`).
- `litigation_conversations` / `litigation_messages` — Module 01.
- `library_favorites` / `library_document_stats` — Module 02.
- `student_module_progress` / `student_evaluation_attempts` — Module 03.
- `professional_drafting_results` — Module 04.

## Ce qui n'est pas encore fait

Le schéma existe et est prêt à l'usage, mais **aucun repository de
l'application ne l'utilise encore** — les quatre modules continuent de
fonctionner en mémoire locale (mêmes limites qu'avant). Migrer chaque
module vers ces tables est l'étape suivante de la feuille de route, une
fois l'authentification vérifiée en conditions réelles.
