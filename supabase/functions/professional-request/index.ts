// Réception d'une demande d'acte ou de rendez-vous, puis accusé de réception.
// Déploiement : supabase functions deploy professional-request --project-ref <ref>

import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { escapeHtml, sendTransactionalEmail } from "../_shared/email.ts";
import { userClient } from "../_shared/supabase.ts";

const KINDS = new Set(["legalAct", "expertAppointment"]);
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

  if (!KINDS.has(kind) || !CATEGORIES.has(category) || !URGENCIES.has(urgency)) {
    return jsonResponse({ error: "paramètres de demande invalides" }, 400);
  }
  if (kind === "expertAppointment" && (!desiredDate || !MODES.has(appointmentMode ?? ""))) {
    return jsonResponse({ error: "date et format de rendez-vous requis" }, 400);
  }
  if (kind === "legalAct" && !actType) return jsonResponse({ error: "type d'acte requis" }, 400);
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
    const destination = Deno.env.get("PROFESSIONAL_REQUEST_DESTINATION") ?? "";
    const recipients = destination ? [email, destination] : email;
    mailDispatched = await sendTransactionalEmail({
      to: recipients,
      subject: `JurisIA — demande reçue (${kind === "legalAct" ? "acte juridique" : "rendez-vous"})`,
      html: `<p>Bonjour ${escapeHtml(fullName)},</p>
        <p>Votre demande <strong>${escapeHtml(request.id)}</strong> a bien été reçue par JurisIA.</p>
        <p>Notre équipe reviendra vers vous avec un accusé de prise en charge, un devis ou une proposition de créneau.</p>
        <p>Type : ${escapeHtml(kind)}<br>Professionnel : ${escapeHtml(category)}<br>Urgence : ${escapeHtml(urgency)}</p>`,
    });
  } catch (mailError) {
    console.error("Échec de l'accusé e-mail", mailError);
  }

  return jsonResponse({ request, mailDispatched });
});
