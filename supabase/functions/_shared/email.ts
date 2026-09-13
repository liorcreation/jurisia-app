export type TransactionalEmail = {
  to: string | string[];
  subject: string;
  html: string;
};

/**
 * Envoi transactionnel optionnel via Resend. La persistance Supabase reste
 * la source de vérité si la clé de messagerie n'est pas encore configurée.
 */
export async function sendTransactionalEmail(email: TransactionalEmail): Promise<boolean> {
  const apiKey = Deno.env.get("RESEND_API_KEY") ?? "";
  const from = Deno.env.get("RESEND_FROM_EMAIL") ?? "JurisIA <notifications@jurisia.app>";
  if (!apiKey) return false;

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ from, to: email.to, subject: email.subject, html: email.html }),
  });
  if (!response.ok) {
    throw new Error(`Le prestataire e-mail a répondu ${response.status}`);
  }
  return true;
}

export function escapeHtml(value: unknown): string {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
