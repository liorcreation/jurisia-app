// Edge Function `billing-webhook` — appelée en serveur-à-serveur par le
// prestataire de paiement (pas de JWT : `verify_jwt = false` dans
// supabase/config.toml). Ne fait JAMAIS confiance au seul contenu reçu :
// elle re-vérifie l'état de la transaction auprès du prestataire, compare le
// montant, puis active l'abonnement via `jurisia_billing_apply` (idempotent).
//
// Déploiement : supabase functions deploy billing-webhook --project-ref <ref>

import { billingProviderFromEnv } from "../_shared/billing.ts";
import { serviceClient } from "../_shared/supabase.ts";

async function extractTransactionId(req: Request): Promise<string> {
  const contentType = req.headers.get("content-type") ?? "";
  try {
    if (contentType.includes("application/json")) {
      const body = await req.json();
      return String(body?.cpm_trans_id ?? body?.transaction_id ?? body?.tx ?? "");
    }
    const form = await req.formData();
    return String(form.get("cpm_trans_id") ?? form.get("transaction_id") ?? "");
  } catch {
    return new URL(req.url).searchParams.get("tx") ?? "";
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

  const transactionId = await extractTransactionId(req);
  if (!transactionId) return new Response("transaction_id manquant", { status: 400 });

  let verify;
  try {
    verify = await billingProviderFromEnv().verify(transactionId);
  } catch (e) {
    console.error(JSON.stringify({ event: "verify_error", transactionId, error: String(e) }));
    return new Response("verification failed", { status: 502 });
  }

  if (verify.status === "pending") {
    // On accuse réception ; le prestataire réessaiera.
    return new Response("pending", { status: 200 });
  }

  const admin = serviceClient();

  // Garde-fou anti-altération : le montant confirmé doit correspondre à
  // l'intention créée côté serveur.
  if (verify.status === "paid" && verify.amountFcfa != null) {
    const { data: intent } = await admin
      .from("payment_intents")
      .select("amount_fcfa")
      .eq("transaction_id", transactionId)
      .maybeSingle();
    if (intent && Number(intent.amount_fcfa) !== Number(verify.amountFcfa)) {
      console.error(JSON.stringify({
        event: "amount_mismatch",
        transactionId,
        expected: intent.amount_fcfa,
        got: verify.amountFcfa,
      }));
      await admin.rpc("jurisia_billing_apply", {
        p_transaction_id: transactionId,
        p_new_status: "failed",
      });
      return new Response("amount mismatch", { status: 409 });
    }
  }

  const { error } = await admin.rpc("jurisia_billing_apply", {
    p_transaction_id: transactionId,
    p_new_status: verify.status,
  });
  if (error) {
    console.error(JSON.stringify({ event: "apply_error", transactionId, error: error.message }));
    return new Response("apply failed", { status: 500 });
  }

  console.log(JSON.stringify({ event: "applied", transactionId, status: verify.status }));
  return new Response("ok", { status: 200 });
});
