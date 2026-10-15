// Réception d'une demande d'acte ou de rendez-vous, puis accusé de réception.
// Déploiement : supabase functions deploy professional-request --project-ref <ref>

import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { escapeHtml, sendTransactionalEmail } from "../_shared/email.ts";
import { userClient } from "../_shared/supabase.ts";

const KINDS = new Set(["legalAct", "expertAppointment", "trainingEnrollment"]);
// Les anciennes valeurs restent acceptées pour les demandes déjà émises ;
// les nouvelles demandes utilisent la typologie métier de l'espace Services.
const CATEGORIES = new Set([
  "services_notariaux",
  "services_avocats",
  "services_huissier",
  "jurisconsulte",
  "creation_entreprise_association",
  "creation_societes",
  "creation_cooperatives",
  "consultation_approfondie",
  "notaire",
  "avocat",
  "juriste",
  "huissier",
  "greffier",
  "juge",
]);
const URGENCIES = new Set(["standard", "priority", "urgent"]);
const MODES = new Set(["phone", "video", "inPerson"]);

function isValidEmail(email: string): boolean {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "méthode non autorisée" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) return jsonResponse({ error: "non authentifié" }, 401);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "corps JSON invalide" }, 400);
  }

  const kind = String(body.kind ?? "");
  const category = String(body.category ?? "");
  const actType = body.actType == null ? null : String(body.actType).trim();
  const fullName = String(body.fullName ?? "").trim();
  const email = String(body.email ?? "").trim();
  const phone = String(body.phone ?? "").trim();
  const details = String(body.details ?? "").trim();
  const urgency = String(body.urgency ?? "standard");
  const desiredDate = body.desiredDate == null ? null : String(body.desiredDate).slice(0, 10);
  const appointmentMode = body.appointmentMode == null ? null : String(body.appointmentMode);
  const attachmentNames = Array.isArray(body.attachmentNames)
    ? body.attachmentNames.map((value) => String(value).trim()).filter(Boolean).slice(0, 30)
    : [];
  const rawAttachments = Array.isArray(body.attachments) ? body.attachments.slice(0, 4) : [];
  const attachments: Array<{ filename: string; content: string }> = [];
  let attachmentBytes = 0;
  for (const item of rawAttachments) {
    if (!item || typeof item !== "object") return jsonResponse({ error: "pièce jointe invalide" }, 400);
    const filename = String((item as Record<string, unknown>).filename ?? "").trim();
    const content = String((item as Record<string, unknown>).contentBase64 ?? "");
    const extension = filename.split(".").pop()?.toLowerCase() ?? "";
    if (!filename || !["pdf", "doc", "docx", "txt", "jpg", "jpeg", "png"].includes(extension)) {
      return jsonResponse({ error: "format de pièce jointe non pris en charge" }, 400);
    }
    if (!/^[A-Za-z0-9+/]*={0,2}$/.test(content)) return jsonResponse({ error: "encodage de pièce jointe invalide" }, 400);
    const size = Math.floor(content.length * 3 / 4);
    attachmentBytes += size;
    if (size <= 0 || size > 5 * 1024 * 1024 || attachmentBytes > 8 * 1024 * 1024) {
      return jsonResponse({ error: "taille maximale des pièces dépassée" }, 400);
    }
    attachments.push({ filename, content });
  }

  if (!KINDS.has(kind) || !CATEGORIES.has(category) || !URGENCIES.has(urgency)) {
    return jsonResponse({ error: "paramètres de demande invalides" }, 400);
  }
  if (kind === "expertAppointment" && (!desiredDate || !MODES.has(appointmentMode ?? ""))) {
    return jsonResponse({ error: "date et format de rendez-vous requis" }, 400);
  }
  if ((kind === "legalAct" || kind === "trainingEnrollment") && !actType) {
    return jsonResponse({ error: "type d'acte ou de formation requis" }, 400);
  }
  if (fullName.length < 2 || !isValidEmail(email) || phone.length < 6 || details.length < 12) {
    return jsonResponse({ error: "coordonnées ou description incomplètes" }, 400);
  }

  const supabase = userClient(authHeader);
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData?.user) return jsonResponse({ error: "session invalide" }, 401);

  const requestedId = String(body.id ?? "");
  const id = /^[0-9a-f-]{36}$/i.test(requestedId) ? requestedId : undefined;
  const { data: request, error } = await supabase
    .from("professional_service_requests")
    .insert({
      ...(id ? { id } : {}),
      user_id: userData.user.id,
      kind,
      category,
      act_type: actType,
      full_name: fullName,
      email,
      phone,
      details,
      urgency,
      attachment_names: attachmentNames,
      desired_date: desiredDate,
      appointment_mode: appointmentMode,
    })
    .select()
    .single();
  if (error || !request) return jsonResponse({ error: error?.message ?? "enregistrement impossible" }, 400);

  let mailDispatched = false;
  try {
    const destination = "Jurisia05@gmail.com";
    const kindLabel = kind === "trainingEnrollment"
      ? "inscription à une formation"
      : kind === "legalAct" ? "demande de prestation" : "rendez-vous";
    const escapedDetails = escapeHtml(details).replaceAll("\n", "<br>");
    const attachmentList = attachments.length
      ? `<p><strong>Pièces jointes :</strong> ${attachments.map((file) => escapeHtml(file.filename)).join(", ")}</p>`
      : "";
    mailDispatched = await sendTransactionalEmail({
      to: destination,
      subject: `JurisIA — ${kindLabel} · ${escapeHtml(actType ?? category)}`,
      replyTo: email,
      html: `<h2>Nouvelle demande JurisIA</h2>
        <p><strong>Référence :</strong> ${escapeHtml(request.id)}</p>
        <p><strong>Demandeur :</strong> ${escapeHtml(fullName)}<br>
        <strong>E-mail :</strong> ${escapeHtml(email)}<br>
        <strong>Téléphone :</strong> ${escapeHtml(phone)}</p>
        <p><strong>Type :</strong> ${escapeHtml(kindLabel)}<br>
        <strong>Service :</strong> ${escapeHtml(category)}<br>
        <strong>Prestation / formation :</strong> ${escapeHtml(actType ?? "—")}<br>
        <strong>Urgence :</strong> ${escapeHtml(urgency)}</p>
        <p><strong>Demande :</strong><br>${escapedDetails}</p>${attachmentList}`,
      attachments,
    });
    if (mailDispatched) {
      await sendTransactionalEmail({
        to: email,
        subject: `JurisIA — accusé de réception ${request.id}`,
        html: `<p>Bonjour ${escapeHtml(fullName)},</p>
          <p>Votre demande <strong>${escapeHtml(request.id)}</strong> a bien été transmise à l’équipe JurisIA (${escapeHtml(destination)}).</p>
          <p>Nous reviendrons vers vous par e-mail pour son suivi.</p>`,
      });
    }
  } catch (mailError) {
    console.error("Échec de l'accusé e-mail", mailError);
  }

  return jsonResponse({ request, mailDispatched });
});
