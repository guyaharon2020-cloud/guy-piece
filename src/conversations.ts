import type Anthropic from "@anthropic-ai/sdk";

// Per-sender conversation history, kept in memory. This is lost on restart -
// swap for a database or Redis if you need it to survive deploys.
const MAX_TURNS = 20;

const histories = new Map<string, Anthropic.MessageParam[]>();

export function getHistory(sender: string): Anthropic.MessageParam[] {
  return histories.get(sender) ?? [];
}

export function appendTurn(
  sender: string,
  userMessage: string,
  assistantContent: Anthropic.ContentBlockParam[],
): void {
  const history = getHistory(sender);
  history.push({ role: "user", content: userMessage });
  history.push({ role: "assistant", content: assistantContent });

  // Keep only the most recent turns so the request stays bounded.
  const trimmed = history.slice(-MAX_TURNS * 2);
  histories.set(sender, trimmed);
}
