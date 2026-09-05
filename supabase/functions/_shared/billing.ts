// Abstraction du prestataire de paiement, partagée par les Edge Functions
// `billing-checkout` et `billing-webhook`.
//
// Deux implémentations :
//  - MockProvider     : succès immédiat, aucun appel réseau (dev / démo).
//  - CinetPayProvider : CinetPay (Mobile Money + carte), sandbox ou prod.
//
// Ajouter PayDunya / Fedapay / Flutterwave revient à écrire une classe de
// plus qui implémente `BillingProvider`.

export interface CheckoutRequest {
  transactionId: string;
  amountFcfa: number;
  currency: string;
  planName: string;
  customerId: string;
  customerEmail: string;
  returnUrl: string;
  notifyUrl: string;
}

export interface CheckoutResult {
  checkoutUrl: string;
  /**
   * `true` = paiement considéré confirmé immédiatement (provider mock) :
   * `billing-checkout` appelle alors `jurisia_billing_apply` sans attendre
   * de notification. `false` = on attend le webhook du prestataire.
   */
  autoConfirm: boolean;
}

/** Jeton d'accès CinetPay mis en cache le temps de sa validité (API v1). */
interface CachedToken {
  value: string;
  expiresAt: number;
}

export interface VerifyResult {
  status: "paid" | "failed" | "expired" | "pending";
  amountFcfa?: number;
}

export interface BillingProvider {
  readonly name: string;
  createCheckout(req: CheckoutRequest): Promise<CheckoutResult>;
  /** Re-vérifie l'état d'une transaction — ne jamais se fier au seul webhook. */
  verify(transactionId: string): Promise<VerifyResult>;
}

class MockProvider implements BillingProvider {
  readonly name = "mock";

  createCheckout(req: CheckoutRequest): Promise<CheckoutResult> {
    return Promise.resolve({
      checkoutUrl: `${req.returnUrl}?tx=${encodeURIComponent(req.transactionId)}&mock=1`,
      autoConfirm: true,
    });
  }

  verify(_transactionId: string): Promise<VerifyResult> {
    return Promise.resolve({ status: "paid" });
  }
}

// CinetPay a retiré, courant 2026, son ancienne « Checkout API v2 »
// (api-checkout.cinetpay.com, authentification par simple couple
// apikey/site_id) au profit d'une API v1 authentifiée par jeton OAuth
// (api.cinetpay.net en test, api.cinetpay.co en production ; identifiants :
// clé API + MOT DE PASSE API, ce dernier à générer dans Intégrations → API
// du tableau de bord). `site_id` n'existe plus côté API — on ne le lit ni ne
// l'envoie. Contrat vérifié dans le SDK PHP officiel (cinetpay/cinetpay-php-sdk,
// à jour août 2026) : POST /v1/oauth/login, POST /v1/payment, GET
// /v1/payment/{transactionId}.
class CinetPayProvider implements BillingProvider {
  readonly name = "cinetpay";
  private cachedToken: CachedToken | null = null;

  constructor(
    private readonly apiKey: string,
    private readonly apiPassword: string,
    private readonly baseUrl: string,
  ) {}

  private async getAccessToken(): Promise<string> {
    // Marge de 5 s pour ne jamais envoyer un jeton expiré de justesse.
    if (this.cachedToken && this.cachedToken.expiresAt > Date.now() + 5_000) {
      return this.cachedToken.value;
    }
    const res = await fetch(`${this.baseUrl}/v1/oauth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ api_key: this.apiKey, api_password: this.apiPassword }),
    });
    const data = await res.json();
    if (!data?.access_token) {
      throw new Error(
        `CinetPay (authentification) : ${data?.description ?? data?.status ?? "jeton refusé"}`,
      );
    }
    const ttlSeconds = Number(data.expires_in);
    this.cachedToken = {
      value: String(data.access_token),
      expiresAt: Date.now() + (Number.isFinite(ttlSeconds) ? ttlSeconds : 60) * 1000,
    };
    return this.cachedToken.value;
  }

  async createCheckout(req: CheckoutRequest): Promise<CheckoutResult> {
    // CinetPay refuse les montants non multiples de 5 en XOF/XAF.
    if (req.currency === "XOF" || req.currency === "XAF") {
      if (req.amountFcfa % 5 !== 0) {
        throw new Error(`CinetPay: montant ${req.amountFcfa} non multiple de 5 (${req.currency}).`);
      }
    }
    const token = await this.getAccessToken();
    // Le prénom/nom client sont exigés par l'API ; on n'a que l'e-mail, on en
    // dérive un nom lisible à défaut.
    const fallbackName = (req.customerEmail.split("@")[0] || "Client").slice(0, 60);
    const res = await fetch(`${this.baseUrl}/v1/payment`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`,
      },
      body: JSON.stringify({
        currency: req.currency,
        merchant_transaction_id: req.transactionId,
        amount: req.amountFcfa,
        success_url: req.returnUrl,
        failed_url: req.returnUrl,
        notify_url: req.notifyUrl,
        lang: "fr",
        designation: `JurisIA — ${req.planName}`,
        client_first_name: fallbackName,
        client_last_name: "JurisIA",
        client_email: req.customerEmail,
      }),
    });
    const data = await res.json();
    if (!data?.payment_url) {
      throw new Error(
        `CinetPay: ${data?.description ?? data?.status ?? "réponse inattendue"} (code ${data?.code})`,
      );
    }
    return { checkoutUrl: String(data.payment_url), autoConfirm: false };
  }

  async verify(transactionId: string): Promise<VerifyResult> {
    const token = await this.getAccessToken();
    const res = await fetch(`${this.baseUrl}/v1/payment/${encodeURIComponent(transactionId)}`, {
      method: "GET",
      headers: { "Authorization": `Bearer ${token}` },
    });
    const data = await res.json();
    const status = data?.status;

    // Contrairement à l'ancienne API, la vérification /v1/payment/{id} ne
    // renvoie plus le montant réglé : `amountFcfa` reste undefined pour ce
    // prestataire. Ce n'est pas une régression de sécurité — `billing-webhook`
    // ne fait de toute façon jamais confiance au contenu du webhook lui-même ;
    // c'est CETTE requête authentifiée (Bearer) qui fait foi, sur un
    // transaction_id que nous seuls avons généré et lié à un montant fixé
    // côté serveur au moment de la création de l'intention.
    if (status === "SUCCESS") return { status: "paid" };
    if (status === "FAILED") return { status: "failed" };
    if (status === "EXPIRED") return { status: "expired" };
    return { status: "pending" };
  }
}

export function billingProviderFromEnv(): BillingProvider {
  const name = Deno.env.get("BILLING_PROVIDER") ?? "mock";

  if (name === "cinetpay") {
    const apiKey = Deno.env.get("CINETPAY_API_KEY") ?? "";
    const apiPassword = Deno.env.get("CINETPAY_API_PASSWORD") ?? "";
    // Par défaut le domaine de TEST (api.cinetpay.net) — la production vit
    // sur api.cinetpay.co, à renseigner explicitement dans CINETPAY_BASE_URL
    // au passage en prod (voir CHECKLIST_SANDBOX.md).
    const baseUrl = Deno.env.get("CINETPAY_BASE_URL") ?? "https://api.cinetpay.net";
    if (
      !apiKey || !apiPassword ||
      apiKey.startsWith("SANDBOX_A_REMPLACER") || apiPassword.startsWith("SANDBOX_A_REMPLACER")
    ) {
      throw new Error(
        "CinetPay non configuré : renseignez CINETPAY_API_KEY et CINETPAY_API_PASSWORD.",
      );
    }
    return new CinetPayProvider(apiKey, apiPassword, baseUrl);
  }

  return new MockProvider();
}

/** Identifiant de transaction lisible et unique. */
export function newTransactionId(): string {
  return `jurisia-${Date.now()}-${crypto.randomUUID().slice(0, 8)}`;
}
