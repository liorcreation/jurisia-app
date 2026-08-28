# Mise en route du paiement — sandbox CinetPay

Suivi pas à pas pour passer de `mock` à CinetPay en mode Test. Tout le code
est déjà en place (branche fusionnée dans `main`, commit `4ef6545`).

## 0. Pré-requis (une fois)

- [ ] Migration `server/supabase/migration_009_billing.sql` exécutée dans le
      SQL Editor. ✅ *(validée le 2026-08-28)*
- [ ] CLI Supabase installée et connectée : `supabase login`,
      `supabase link --project-ref gfpguuuzzyqoxjkhlhli`.
- [ ] Compte CinetPay créé, un **service en mode « Test »** ajouté
      (Tableau de bord → Services). Récupérer `API_KEY` et `SITE_ID` du
      service Test dans Intégrations → API.

## 1. Renseigner les clés

`supabase/functions/.env` existe déjà (ignoré par git) avec des placeholders.
Remplacer :

```
CINETPAY_API_KEY=<clé API du service Test>
CINETPAY_SITE_ID=<site_id du service Test>
```

Laisser `BILLING_PROVIDER=cinetpay`, `CINETPAY_BASE_URL`,
`APP_PUBLIC_URL` et `BILLING_NOTIFY_URL` tels quels.

> Tant que les clés commencent par `SANDBOX_A_REMPLACER`, `billing-checkout`
> renvoie une erreur 500 exprès (garde-fou dans `_shared/billing.ts`).

## 2. Pousser les secrets + déployer

```bash
supabase secrets set --env-file supabase/functions/.env --project-ref gfpguuuzzyqoxjkhlhli
supabase functions deploy billing-checkout --project-ref gfpguuuzzyqoxjkhlhli
supabase functions deploy billing-webhook  --project-ref gfpguuuzzyqoxjkhlhli
```

`billing-webhook` se déploie sans JWT (`supabase/config.toml`,
`verify_jwt = false`) — c'est voulu : la sécurité vient de la re-vérification
du paiement auprès de CinetPay.

## 3. Déclarer l'URL de notification chez CinetPay

Service Test → configuration → **URL de notification** :

```
https://gfpguuuzzyqoxjkhlhli.supabase.co/functions/v1/billing-webhook
```

## 4. Tester le parcours

1. Ouvrir l'app, écran **Mon abonnement**, choisir **JurisIA+** (2 500 F).
2. La page CinetPay Test s'ouvre → simuler un paiement Orange/Moov Money.
3. CinetPay appelle `billing-webhook` → re-vérifie via `/v2/payment/check`,
   contrôle le montant, puis `jurisia_billing_apply` (idempotent) passe la
   ligne `subscriptions` à `active`.
4. De retour dans l'app, les droits se rafraîchissent (`EntitlementsController`).

### Vérifs SQL

```sql
select transaction_id, status, amount_fcfa, checkout_url
  from public.payment_intents order by created_at desc limit 5;

select user_id, plan_code, status, current_period_end, psp, psp_ref
  from public.subscriptions order by updated_at desc limit 5;

select action, target_id, reason, created_at
  from public.admin_audit_log
  where action = 'subscription.activated' order by created_at desc limit 5;
```

## 5. Repli sans compte CinetPay

Mettre `BILLING_PROVIDER=mock` dans `.env`, re-pousser les secrets : le bouton
« Choisir cette offre » active l'abonnement immédiatement, sans appel externe.

## Passage en production (plus tard)

- Service CinetPay en mode **Production** (KYC validé).
- Nouvelles `CINETPAY_API_KEY` / `CINETPAY_SITE_ID` de prod → `secrets set`.
- `APP_PUBLIC_URL` = domaine public réel.
- Prix `plans.price_fcfa` confirmés par l'étude de marché
  (actuels : plus 2 500 · étudiant 1 000 · pro 15 000 · cabinet sur devis).
