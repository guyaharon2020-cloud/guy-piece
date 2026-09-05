import "dotenv/config";
import express from "express";
import { getReply } from "./claude.js";
import { extractTextMessages, sendWhatsAppMessage, verifySignature } from "./whatsapp.js";

const PORT = Number(process.env.PORT ?? 3000);
const VERIFY_TOKEN = process.env.WHATSAPP_VERIFY_TOKEN ?? "";

const app = express();

app.use(
  express.json({
    verify: (req, _res, buf) => {
      (req as express.Request & { rawBody: Buffer }).rawBody = buf;
    },
  }),
);

// Meta calls this once, when you save the webhook URL in the app dashboard,
// to confirm you control this endpoint.
app.get("/webhook", (req, res) => {
  const mode = req.query["hub.mode"];
  const token = req.query["hub.verify_token"];
  const challenge = req.query["hub.challenge"];

  if (mode === "subscribe" && token === VERIFY_TOKEN) {
    res.status(200).send(challenge);
  } else {
    res.sendStatus(403);
  }
});

// Meta calls this for every incoming message, delivery status, etc.
app.post("/webhook", async (req, res) => {
  const signature = req.header("x-hub-signature-256");
  const rawBody = (req as express.Request & { rawBody: Buffer }).rawBody;

  if (!verifySignature(rawBody, signature)) {
    res.sendStatus(401);
    return;
  }

  // Acknowledge immediately - Meta expects a fast 200 and will retry
  // otherwise, which would end up sending duplicate replies.
  res.sendStatus(200);

  const messages = extractTextMessages(req.body);
  for (const message of messages) {
    handleIncomingMessage(message.from, message.text).catch((error) => {
      console.error(`Failed to handle message from ${message.from}:`, error);
    });
  }
});

async function handleIncomingMessage(from: string, text: string): Promise<void> {
  const reply = await getReply(from, text);
  await sendWhatsAppMessage(from, reply);
}

app.get("/", (_req, res) => {
  res.send("WhatsApp <-> Claude agent is running.");
});

app.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
