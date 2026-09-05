# guy-piece — WhatsApp Agent

A WhatsApp chatbot backed by Claude. Messages sent to your WhatsApp number are
forwarded (via Meta's WhatsApp Cloud API webhook) to Claude, and the reply is
sent back on WhatsApp. Each phone number gets its own short conversation
history so the bot remembers recent context.

## How it works

```
Your phone (WhatsApp) <-> Meta WhatsApp Cloud API <-> this server (webhook) <-> Claude API
```

- `src/index.ts` — Express server exposing `GET/POST /webhook`
- `src/whatsapp.ts` — sending/receiving messages via the WhatsApp Cloud API, webhook signature verification
- `src/claude.ts` — calls the Claude API (`@anthropic-ai/sdk`) for a reply
- `src/conversations.ts` — in-memory per-sender chat history (resets on restart)

## 1. Set up a Meta WhatsApp app

1. Go to [developers.facebook.com](https://developers.facebook.com/) → create an app → add the **WhatsApp** product.
2. Under **WhatsApp → API Setup** you'll get a temporary access token, a **Phone Number ID**, and a test phone number you can message from your own WhatsApp.
3. Under **App settings → Basic**, copy the **App Secret**.
4. For a permanent token (recommended once you're past testing): create a System User in Meta Business Settings, generate a permanent token with `whatsapp_business_messaging` permission.

## 2. Configure environment variables

```bash
cp .env.example .env
```

Fill in:
- `ANTHROPIC_API_KEY` — from [console.anthropic.com](https://console.anthropic.com/settings/keys)
- `WHATSAPP_TOKEN` — the access token from step 1
- `WHATSAPP_PHONE_NUMBER_ID` — from API Setup
- `WHATSAPP_VERIFY_TOKEN` — make up any random string; you'll enter the same value in the Meta dashboard
- `WHATSAPP_APP_SECRET` — the App Secret from step 1

## 3. Run it

```bash
npm install
npm run dev      # local development (auto-reload)
# or
npm run build && npm start
```

The server needs a **public HTTPS URL** for Meta to reach it. For local testing, expose it with a tunnel, e.g.:

```bash
ngrok http 3000
```

## 4. Point the Meta webhook at your server

In your app's **WhatsApp → Configuration**:
- Callback URL: `https://<your-public-url>/webhook`
- Verify token: the same value as `WHATSAPP_VERIFY_TOKEN`
- Subscribe to the `messages` field

Meta will `GET /webhook` to verify ownership (handled automatically), then start `POST`ing incoming messages to it.

## 5. Try it

Message your WhatsApp test number from your phone — you should get a Claude-generated reply back within a few seconds.

## Notes / production considerations

- **Conversation history is in-memory** — it resets whenever the server restarts. Swap `src/conversations.ts` for Redis/a database if you need it to persist.
- **Meta's test numbers can only message pre-approved recipient numbers** (added under API Setup → "To" list) until your app passes Meta's business verification.
- **Rate limits / cost**: every WhatsApp message triggers one Claude API call. Adjust `CLAUDE_MODEL` and the `effort` level in `src/claude.ts` to trade off quality vs. cost/latency.
- **Customize the persona** via the `SYSTEM_PROMPT` env var.
