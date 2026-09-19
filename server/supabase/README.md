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
   niveau des lignes déjà activée sur chacune. Puis exécutez, dans l'ordre,
   les fichiers `migration_002` … `migration_009` (tous idempotents).
   `migration_005_profile_identity.sql` ajoute `profiles.full_name` /
   `profiles.profession` (nom et rôle affichés dans la carte profil de la
   sidebar) et `litigation_conversations.is_favorite` (consultations
   épinglées), et redéploie le déclencheur `on_auth_user_created` pour
   recopier le nom fourni à l'inscription.
   `migration_006_roles_and_audit.sql` pose les fondations de la future
   console d'administration séparée (table `staff_roles`, journal d'audit
   `admin_audit_log`, fonctions `jurisia_has_role` / `jurisia_is_staff`) —
   aucune application cliente n'en dépend encore, elle peut être différée.
   `migration_007_subscriptions_and_usage.sql` met en place l'abonnement :
   catalogue `plans`, `subscriptions`, compteurs `usage_counters` /
   `usage_events`, `ai_limits` par palier, et les RPC `jurisia_entitlements`
   / `jurisia_record_usage` appelées par `lib/core/entitlements/`. Tant
   qu'elle n'est pas appliquée, l'application applique le quota de l'offre
   Découverte depuis un compteur local ; une fois en place, le serveur fait
   foi.
   `migration_008_admin_operations.sql` ouvre au personnel la lecture
   transverse des demandes de mise en relation, des abonnements et de la
   consommation, et expose `jurisia_admin_set_contact_status` (change le
   statut d'une demande **et** écrit au journal d'audit) — utilisé par la
   console d'administration (`lib/admin_main.dart`). Nécessite 006 et 007.
   `migration_009_billing.sql` ajoute `payment_intents` et les fonctions
   `jurisia_billing_create_intent` / `jurisia_billing_apply` appelées par
   les Edge Functions de paiement (`supabase/functions/`, voir leur README).
   Nécessite 006 et 007.
   `migration_010_legal_corpus.sql` crée le corpus public (`legal_documents`,
   `legal_articles`) et son index plein texte français.
   `migration_014_mock_exams.sql` et `migration_015_mock_exam_voice_mode.sql`
   sont conservées comme migrations historiques ; le parcours d'évaluation
   actuel est désormais intégré à chaque module étudiant.
   `migration_016_professional_service_requests.sql` crée les demandes
   structurées d'actes/rendez-vous, avec RLS utilisateur stricte.
   `migration_022_professional_service_categories.sql` remplace la liste
   historique des professions par la typologie complète des services
   professionnels, tout en conservant la compatibilité des anciennes demandes.
   `migration_017_legal_corpus_search.sql` expose la RPC de recherche plein
   texte utilisée par l'application.
   `migration_018_training_catalog_certificates.sql` ajoute le catalogue des
   formations certifiantes/LMD et les certificats signés électroniquement,
   avec une RPC publique de vérification par code.
   `migration_019_family_reference_documents.sql` ajoute les premières
   références documentaires de la collection « Droit des personnes et de la
   famille ».
   `migration_020_family_codes_and_doctrine.sql` actualise cette collection
   avec le Code des personnes et de la famille de 2025, classe le Code de
   1989 comme archive abrogée, et indexe deux thèses doctrinales sous forme
   de synthèses bibliographiques.
   `migration_023_obligations_pack.sql` ajoute les neuf références
   bibliographiques du pack « Droit des obligations ».
   `migration_024_jurisia_obligations_course.sql` ajoute le cours complet
   original JurisIA, avec son texte pédagogique intégral et son plan de
   formation. Les ouvrages externes restent des références documentaires et
   ne sont pas reproduits.

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
- `professional_contact_requests` — Module 05.
- `professional_service_requests` — demandes d'actes, de devis et de
  rendez-vous, notifiées par `professional-request*`.
- `legal_documents` / `legal_articles` — Corpus juridique public et recherche
  plein texte (migrations 010 et 017).
- `training_categories` — Catalogue thématique des formations certifiantes et
  parcours LMD, avec disponibilité pilotable.
- `training_certificates` — Certificats individuels, empreinte de signature,
  code de vérification et lien vers le PDF signé.
- `staff_roles` / `admin_audit_log` — console d'admin (migration 006 ;
  amorcer le premier `super_admin` en insérant sa ligne à la main).
- `plans` / `subscriptions` / `usage_counters` / `usage_events` / `ai_limits` —
  abonnement et quotas (migration 007).
- `payment_intents` — suivi des paiements (migration 009). Les abonnements
  ne s'activent que par un paiement confirmé, via les Edge Functions
  `supabase/functions/billing-*`.

Les demandes professionnelles et le corpus sont maintenant consommés par
leurs repositories Flutter. Le dépôt sécurisé des fichiers binaires reste un
étape distincte : le wizard enregistre les pièces attendues, puis le dépôt
Storage pourra être déclenché depuis le lien de suivi envoyé par e-mail.
