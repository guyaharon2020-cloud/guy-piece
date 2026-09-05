import Anthropic from "@anthropic-ai/sdk";
import { appendTurn, getHistory } from "./conversations.js";

const client = new Anthropic();

const MODEL = process.env.CLAUDE_MODEL ?? "claude-opus-5";
const SYSTEM_PROMPT =
  process.env.SYSTEM_PROMPT ??
  "You are a helpful, friendly assistant chatting with the user over WhatsApp. Keep replies concise and conversational.";

/**
 * Sends the user's message plus their prior history to Claude and returns the
 * reply text, recording the turn in the per-sender conversation history.
 */
export async function getReply(sender: string, userMessage: string): Promise<string> {
  const history = getHistory(sender);

  try {
    const response = await client.messages.create({
      model: MODEL,
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      output_config: { effort: "medium" },
      messages: [...history, { role: "user", content: userMessage }],
    });

    appendTurn(sender, userMessage, response.content);

    const textBlock = response.content.find((block) => block.type === "text");
    return textBlock?.text ?? "Sorry, I didn't get a response - try again?";
  } catch (error) {
    if (error instanceof Anthropic.AuthenticationError) {
      console.error("Anthropic authentication error:", error.message);
      return "Something's misconfigured on my end (auth) - please tell the admin.";
    } else if (error instanceof Anthropic.RateLimitError) {
      console.error("Anthropic rate limited:", error.message);
      return "I'm a bit overloaded right now - please try again in a moment.";
    } else if (error instanceof Anthropic.APIError) {
      console.error(`Anthropic API error ${error.status}:`, error.message);
      return "Sorry, I ran into an error processing that.";
    }
    throw error;
  }
}
