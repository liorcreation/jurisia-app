// Notification staff : met à jour le statut/devis d'une demande et envoie
// le message transactionnel au demandeur.
// Déploiement : supabase functions deploy professional-request-notify --project-ref <ref>

import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { escapeHtml, sendTransactionalEmail } from "../_shared/email.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

const STATUSES = new Set(["acknowledged", "quoteReady", "scheduled", "closed", "cancelled"]);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "méthode non autorisée" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) return jsonResponse({ error: "non authentifié" }, 401);
  const caller = userClient(authHeader);
  const { data: userData, error: userError } = await caller.auth.getUser();
  if (userError || !userData?.user) return jsonResponse({ error: "session invalide" }, 401);

  const { data: isStaff, error: staffError } = await caller.rpc("jurisia_is_staff");
  if (staffError || !isStaff) return jsonResponse({ error: "réservé au personnel" }, 403);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "corps JSON invalide" }, 400);
  }

  const requestId = String(body.requestId ?? "");
  const status = String(body.status ?? "");
  if (!/^[0-9a-f-]{36}$/i.test(requestId) || !STATUSES.has(status)) {
    return jsonResponse({ error: "demande ou statut invalide" }, 400);
  }
  const quoteAmount = body.quoteAmount == null ? null : Number(body.quoteAmount);
  if (quoteAmount != null && !Number.isFinite(quoteAmount)) {
    return jsonResponse({ error: "montant de devis invalide" }, 400);
  }

  const admin = serviceClient();
  const { data: current, error: readError } = await admin
    .from("professional_service_requests")
    .select()
    .eq("id", requestId)
    .single();
  if (readError || !current) return jsonResponse({ error: "demande introuvable" }, 404);
  if (status === "quoteReady" && quoteAmount == null && current.quote_amount == null) {
    return jsonResponse({ error: "un montant est requis pour publier un devis" }, 400);
  }

  const { data: updated, error: updateError } = await admin
    .from("professional_service_requests")
    .update({
      status,
      quote_amount: quoteAmount ?? current.quote_amount,
      quote_currency: String(body.quoteCurrency ?? current.quote_currency ?? "XOF"),
      deposit_url: body.depositUrl == null ? current.deposit_url : String(body.depositUrl),
      dropoff_location: body.dropoffLocation == null ? current.dropoff_location : String(body.dropoffLocation),
      pickup_location: body.pickupLocation == null ? current.pickup_location : String(body.pickupLocation),
    })
    .eq("id", requestId)
    .select()
    .single();
  if (updateError || !updated) return jsonResponse({ error: updateError?.message ?? "mise à jour impossible" }, 400);

  let mailDispatched = false;
  try {
    const quote = quoteAmount == null
      ? ""
      : `<p><strong>Montant indicatif :</strong> ${escapeHtml(quoteAmount)} ${escapeHtml(updated.quote_currency)}</p>`;
    mailDispatched = await sendTransactionalEmail({
      to: String(updated.email),
      subject: `JurisIA — mise à jour de votre demande ${requestId}`,
      html: `<p>Bonjour ${escapeHtml(updated.full_name)},</p>
        <p>Votre demande est maintenant au statut : <strong>${escapeHtml(status)}</strong>.</p>
        ${quote}
        <p>Connectez-vous à JurisIA pour consulter les détails et les prochaines instructions.</p>`,
    });
  } catch (mailError) {
    console.error("Échec de la notification e-mail", mailError);
  }

  return jsonResponse({ request: updated, mailDispatched });
});
