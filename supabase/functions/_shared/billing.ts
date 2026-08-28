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

class CinetPayProvider implements BillingProvider {
  readonly name = "cinetpay";

  constructor(
    private readonly apiKey: string,
    private readonly siteId: string,
    private readonly baseUrl: string,
  ) {}

  async createCheckout(req: CheckoutRequest): Promise<CheckoutResult> {
    const res = await fetch(`${this.baseUrl}/v2/payment`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        apikey: this.apiKey,
        site_id: this.siteId,
        transaction_id: req.transactionId,
        amount: req.amountFcfa,
        currency: req.currency,
        description: `JurisIA — ${req.planName}`,
        notify_url: req.notifyUrl,
        return_url: req.returnUrl,
        channels: "ALL",
        customer_id: req.customerId,
        customer_email: req.customerEmail,
      }),
    });
    const data = await res.json();
    if (String(data?.code) !== "201" || !data?.data?.payment_url) {
      throw new Error(`CinetPay: ${data?.message ?? "réponse inattendue"} (code ${data?.code})`);
    }
    return { checkoutUrl: String(data.data.payment_url), autoConfirm: false };
  }

  async verify(transactionId: string): Promise<VerifyResult> {
    const res = await fetch(`${this.baseUrl}/v2/payment/check`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        apikey: this.apiKey,
        site_id: this.siteId,
        transaction_id: transactionId,
      }),
    });
    const data = await res.json();
    const status = data?.data?.status;
    const amount = Number(data?.data?.amount);

    if (String(data?.code) === "00" && status === "ACCEPTED") {
      return { status: "paid", amountFcfa: Number.isFinite(amount) ? amount : undefined };
    }
    if (status === "REFUSED") return { status: "failed" };
    if (String(data?.code) === "662" || status === "EXPIRED") return { status: "expired" };
    return { status: "pending" };
  }
}

export function billingProviderFromEnv(): BillingProvider {
  const name = Deno.env.get("BILLING_PROVIDER") ?? "mock";

  if (name === "cinetpay") {
    const apiKey = Deno.env.get("CINETPAY_API_KEY") ?? "";
    const siteId = Deno.env.get("CINETPAY_SITE_ID") ?? "";
    const baseUrl = Deno.env.get("CINETPAY_BASE_URL") ?? "https://api-checkout.cinetpay.com";
    if (!apiKey || !siteId || apiKey.startsWith("SANDBOX_A_REMPLACER")) {
      throw new Error(
        "CinetPay non configuré : renseignez CINETPAY_API_KEY et CINETPAY_SITE_ID.",
      );
    }
    return new CinetPayProvider(apiKey, siteId, baseUrl);
  }

  return new MockProvider();
}

/** Identifiant de transaction lisible et unique. */
export function newTransactionId(): string {
  return `jurisia-${Date.now()}-${crypto.randomUUID().slice(0, 8)}`;
}
