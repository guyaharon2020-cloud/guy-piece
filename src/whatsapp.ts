import crypto from "node:crypto";

const GRAPH_API_VERSION = "v21.0";

const WHATSAPP_TOKEN = process.env.WHATSAPP_TOKEN ?? "";
const PHONE_NUMBER_ID = process.env.WHATSAPP_PHONE_NUMBER_ID ?? "";
const APP_SECRET = process.env.WHATSAPP_APP_SECRET ?? "";

export interface IncomingTextMessage {
  from: string;
  text: string;
  messageId: string;
}

/**
 * Verifies the X-Hub-Signature-256 header Meta attaches to every webhook
 * delivery, so we only act on requests that really came from Meta.
 */
export function verifySignature(rawBody: Buffer, signatureHeader: string | undefined): boolean {
  if (!APP_SECRET) {
    // No app secret configured - skip verification (development only).
    return true;
  }
  if (!signatureHeader?.startsWith("sha256=")) {
    return false;
  }
  const expected = crypto.createHmac("sha256", APP_SECRET).update(rawBody).digest("hex");
  const provided = signatureHeader.slice("sha256=".length);
  const expectedBuf = Buffer.from(expected, "hex");
  const providedBuf = Buffer.from(provided, "hex");
  return (
    expectedBuf.length === providedBuf.length &&
    crypto.timingSafeEqual(expectedBuf, providedBuf)
  );
}

/**
 * Pulls the text messages out of a WhatsApp Cloud API webhook payload.
 * Non-text messages (images, audio, stickers, statuses, ...) are ignored.
 */
export function extractTextMessages(body: unknown): IncomingTextMessage[] {
  const messages: IncomingTextMessage[] = [];

  const entries = (body as { entry?: unknown[] })?.entry ?? [];
  for (const entry of entries) {
    const changes = (entry as { changes?: unknown[] })?.changes ?? [];
    for (const change of changes) {
      const value = (change as { value?: unknown })?.value as
        | { messages?: unknown[] }
        | undefined;
      const rawMessages = value?.messages ?? [];
      for (const raw of rawMessages) {
        const msg = raw as {
          id: string;
          from: string;
          type: string;
          text?: { body: string };
        };
        if (msg.type === "text" && msg.text?.body) {
          messages.push({ from: msg.from, text: msg.text.body, messageId: msg.id });
        }
      }
    }
  }

  return messages;
}

/** Sends a plain-text WhatsApp message to `to` via the Cloud API. */
export async function sendWhatsAppMessage(to: string, text: string): Promise<void> {
  const url = `https://graph.facebook.com/${GRAPH_API_VERSION}/${PHONE_NUMBER_ID}/messages`;

  const response = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${WHATSAPP_TOKEN}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      messaging_product: "whatsapp",
      to,
      type: "text",
      text: { body: text },
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`WhatsApp send failed (${response.status}): ${errorBody}`);
  }
}
