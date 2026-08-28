# Edge Functions — paiement JurisIA

Deux fonctions Deno gèrent l'abonnement payant. Elles s'appuient sur
`server/supabase/migration_009_billing.sql` (table `payment_intents`,
fonctions `jurisia_billing_create_intent` / `jurisia_billing_apply`).

| Fonction | Appelée par | JWT | Rôle |
|---|---|---|---|
| `billing-checkout` | l'application (jeton utilisateur) | oui | crée l'intention de paiement, ouvre un paiement, renvoie l'URL |
| `billing-webhook` | le prestataire de paiement (serveur→serveur) | non | re-vérifie la transaction, active l'abonnement (idempotent) |

## Prestataire

Sélectionné par la variable `BILLING_PROVIDER` :

- **`mock`** (défaut) — succès immédiat, aucun appel externe. `billing-checkout`
  active l'abonnement sur-le-champ. Permet de tester tout le parcours
  (bouton → droits mis à jour) sans compte prestataire.
- **`cinetpay`** — CinetPay (Orange Money, Moov Money, carte). Nécessite
  `CINETPAY_API_KEY` et `CINETPAY_SITE_ID`. Pour les tests, créez un service
  en mode « Test » dans le tableau de bord CinetPay.

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
