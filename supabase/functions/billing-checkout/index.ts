// Edge Function `billing-checkout` — appelée par l'application (JWT de
// l'utilisateur). Crée une intention de paiement, ouvre un paiement chez le
// prestataire, et renvoie l'URL de paiement. Si le prestataire est `mock`,
// l'abonnement est activé immédiatement (aucun webhook).
//
// Déploiement : supabase functions deploy billing-checkout --project-ref <ref>

import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { billingProviderFromEnv, newTransactionId } from "../_shared/billing.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "méthode non autorisée" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) return jsonResponse({ error: "non authentifié" }, 401);

  let planCode = "";
  try {
    const body = await req.json();
    planCode = String(body?.planCode ?? "");
  } catch {
    return jsonResponse({ error: "corps JSON invalide" }, 400);
  }
  if (!planCode) return jsonResponse({ error: "planCode requis" }, 400);

  const supabase = userClient(authHeader);
  const { data: userData, error: userErr } = await supabase.auth.getUser();
  if (userErr || !userData?.user) return jsonResponse({ error: "session invalide" }, 401);
  const user = userData.user;

  let provider;
  try {
    provider = billingProviderFromEnv();
  } catch (e) {
    return jsonResponse({ error: String(e) }, 500);
  }

  const transactionId = newTransactionId();

  const { data: intent, error: intentErr } = await supabase.rpc(
    "jurisia_billing_create_intent",
    { p_plan_code: planCode, p_transaction_id: transactionId, p_provider: provider.name },
  );
  if (intentErr || !intent) {
    return jsonResponse(
      { error: intentErr?.message ?? "création de l'intention de paiement impossible" },
      400,
    );
  }
  const row = Array.isArray(intent) ? intent[0] : intent;

  const appUrl = Deno.env.get("APP_PUBLIC_URL") ?? "";
  const notifyUrl = Deno.env.get("BILLING_NOTIFY_URL") ?? "";

  let checkout;
  try {
    checkout = await provider.createCheckout({
      transactionId,
      amountFcfa: Number(row.amount_fcfa),
      currency: String(row.currency ?? "XOF"),
      planName: planCode,
      customerId: user.id,
      customerEmail: user.email ?? "client@jurisia.app",
      returnUrl: `${appUrl}/billing-return`,
      notifyUrl,
    });
  } catch (e) {
    return jsonResponse({ error: `prestataire de paiement : ${String(e)}` }, 502);
  }

  const admin = serviceClient();
  await admin
    .from("payment_intents")
    .update({ checkout_url: checkout.checkoutUrl })
    .eq("transaction_id", transactionId);

  if (checkout.autoConfirm) {
    const { error: applyErr } = await admin.rpc("jurisia_billing_apply", {
      p_transaction_id: transactionId,
      p_new_status: "paid",
    });
    if (applyErr) return jsonResponse({ error: applyErr.message }, 500);
    return jsonResponse({
      status: "paid",
      transactionId,
      checkoutUrl: checkout.checkoutUrl,
    });
  }

  return jsonResponse({
    status: "pending",
    transactionId,
    checkoutUrl: checkout.checkoutUrl,
  });
});
