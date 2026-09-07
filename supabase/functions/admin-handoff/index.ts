// Edge Function `admin-handoff` — appelée par l'app grand public (JWT de
// l'utilisateur) quand un membre du personnel demande à rejoindre la
// console d'administration. La session Supabase ne se partage jamais entre
// deux origines web différentes (jurisia-app.pages.dev / jurisia-admin
// .pages.dev — chaque site a son propre stockage de session, isolé par le
// navigateur) : cette fonction est le pont. Elle vérifie que l'appelant est
// bien membre du personnel, puis génère un lien magique Supabase (clé
// service_role, jamais côté client) qui authentifie automatiquement ce même
// compte sur la console — jamais besoin de retaper ses identifiants.
//
// Déploiement : supabase functions deploy admin-handoff --project-ref <ref>

import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { serviceClient, userClient } from "../_shared/supabase.ts";

const ADMIN_CONSOLE_URL = Deno.env.get("ADMIN_CONSOLE_URL") ?? "https://jurisia-admin.pages.dev/";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "méthode non autorisée" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader) return jsonResponse({ error: "non authentifié" }, 401);

  const supabase = userClient(authHeader);
  const { data: userData, error: userErr } = await supabase.auth.getUser();
  if (userErr || !userData?.user?.email) return jsonResponse({ error: "session invalide" }, 401);
  const user = userData.user;

  // Vérifié via une requête scopée au JWT de l'appelant (respecte la RLS) —
  // jamais une simple confiance dans ce que le client prétend être.
  const { data: isStaff, error: staffErr } = await supabase.rpc("jurisia_is_staff");
  if (staffErr) return jsonResponse({ error: staffErr.message }, 500);
  if (!isStaff) return jsonResponse({ error: "réservé au personnel" }, 403);

  const admin = serviceClient();
  const { data: link, error: linkErr } = await admin.auth.admin.generateLink({
    type: "magiclink",
    email: user.email,
    options: { redirectTo: ADMIN_CONSOLE_URL },
  });
  if (linkErr || !link?.properties?.action_link) {
    return jsonResponse({ error: linkErr?.message ?? "génération du lien impossible" }, 500);
  }

  // Traçabilité, comme toute action admin — jamais bloquant si l'écriture
  // échoue (le lien reste valide même si l'audit échoue).
  try {
    await supabase.rpc("jurisia_admin_log", {
      p_action: "console_handoff",
      p_target_type: "auth.users",
      p_target_id: user.id,
    });
  } catch {
    // ignoré volontairement
  }

  return jsonResponse({ actionLink: link.properties.action_link });
});
