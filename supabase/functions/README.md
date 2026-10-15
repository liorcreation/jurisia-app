# Edge Functions — paiement et services professionnels JurisIA

Deux fonctions Deno gèrent l'abonnement payant. Elles s'appuient sur
`server/supabase/migration_009_billing.sql` (table `payment_intents`,
fonctions `jurisia_billing_create_intent` / `jurisia_billing_apply`).

Deux fonctions supplémentaires gèrent les demandes d'actes, de rendez-vous et
d'inscriptions en formation. Elles s'appuient sur
`migration_016_professional_service_requests.sql`, `migration_022_professional_service_categories.sql`
et `migration_042_professional_training_enrollment.sql`.

| Fonction | Appelée par | JWT | Rôle |
|---|---|---|---|
| `billing-checkout` | l'application (jeton utilisateur) | oui | crée l'intention de paiement, ouvre un paiement, renvoie l'URL |
| `billing-webhook` | le prestataire de paiement (serveur→serveur) | non | re-vérifie la transaction, active l'abonnement (idempotent) |
| `professional-request` | l'application (jeton utilisateur) | oui | enregistre les demandes, envoie le dossier à Jurisia05@gmail.com et un accusé au demandeur |
| `professional-request-notify` | console du personnel (JWT staff) | oui | applique un statut/devis et notifie le demandeur |

Les e-mails sont envoyés via Resend quand `RESEND_API_KEY` est configurée.
Sans cette clé, la demande reste persistée et pourra être notifiée dès que le
canal transactionnel sera activé.
Le domaine expéditeur défini par `RESEND_FROM_EMAIL` doit être validé dans
Resend. Les pièces jointes d'audit sont transmises avec le courriel interne.

## Prestataire

Sélectionné par la variable `BILLING_PROVIDER` :

- **`mock`** (défaut) — succès immédiat, aucun appel externe. `billing-checkout`
  active l'abonnement sur-le-champ. Permet de tester tout le parcours
  (bouton → droits mis à jour) sans compte prestataire.
- **`cinetpay`** — CinetPay (Orange Money, Moov Money, carte), API v1
  (jeton OAuth). Nécessite `CINETPAY_API_KEY` et `CINETPAY_API_PASSWORD`
  (les deux depuis Intégrations → API). Pour les tests, créez un service
  en mode « Test » dans le tableau de bord CinetPay et utilisez
  `CINETPAY_BASE_URL=https://api.cinetpay.net`.

Ajouter PayDunya / Fedapay / Flutterwave = une classe de plus dans
`_shared/billing.ts` implémentant `BillingProvider`.

## Déploiement (une fois la CLI Supabase installée et connectée)

```bash
# 1. Secrets (depuis la racine du dépôt)
cp supabase/functions/.env.example supabase/functions/.env
#   … remplir supabase/functions/.env …
supabase secrets set --env-file supabase/functions/.env --project-ref <ref>

# 2. Fonctions
supabase functions deploy billing-checkout --project-ref <ref>
supabase functions deploy billing-webhook  --project-ref <ref>
supabase functions deploy professional-request --project-ref <ref>
supabase functions deploy professional-request-notify --project-ref <ref>
```

`billing-webhook` est déployée sans vérification de JWT
(`supabase/config.toml`). Renseignez son URL comme `notify_url` chez le
prestataire :
`https://<project-ref>.supabase.co/functions/v1/billing-webhook`
(et dans `BILLING_NOTIFY_URL`).

## Test local

```bash
supabase functions serve --env-file supabase/functions/.env
# BILLING_PROVIDER=mock : appeler billing-checkout avec un jeton utilisateur
# valide → la ligne subscriptions passe à 'active'.
```
