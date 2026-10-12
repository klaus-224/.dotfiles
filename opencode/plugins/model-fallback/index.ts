import { Model, Plugin } from "@opencode/plugin";
import type { SessionHooks } from "@opencode/plugin/promise/session";
import { loadConfig, type FallbackConfig } from "./config.js";

type Ref = { providerID: string; id: string; variant?: string };
const key = (model: Ref) => `${model.providerID}/${model.id}`;
const same = (a: Ref, b: Ref) => key(a) === key(b) && (a.variant ?? "default") === (b.variant ?? "default");
type State = { origin: Ref; selected: Ref; attempts: number; primary: boolean };

export function fallbackError(error: SessionHooks["retry"]["error"]): boolean {
  // Context overflow belongs to native compaction; authentication and permission
  // errors must remain visible. Never inspect/log response bodies or credentials.
  if (/context|overflow|auth|permission|abort|cancel/i.test(error.type) ||
    error.status === 401 || error.status === 403) return false;
  return [429, 500, 502, 503, 504].includes(error.status ?? 0) ||
    /rate.?limit|quota|usage.?limit/i.test(error.type) ||
    /(?:quota|usage limit|rate limit).*(?:exceed|exhaust|reach)|insufficient_quota|usage_limit_reached/i.test(error.message) ||
    (error.status === 404 && /model.*(?:not found|does not exist|unavailable)/i.test(error.message));
}

// Exported setup is also exercised with a deterministic clock and fake v2 host.
export async function setupFallback(ctx: Plugin.Context, config: FallbackConfig, now = Date.now) {
  if (!config.enabled) return;
  const chain = [config.primary_model, ...config.fallback_models];
  const cooldown = new Map<string, number>();
  const sessions = new Map<string, State>();
  const available = async () => new Set((await ctx.model.list()).data
    .filter(model => model.enabled && model.capabilities.tools)
    .map(model => `${model.providerID}/${model.id}`));
  const ready = (id: string) => (cooldown.get(id) ?? 0) <= now();
  const notify = (message: string) => {
    if (config.notify_on_fallback) console.info(`[model-fallback] ${message}`);
  };
  const remember = (sessionID: string, state: State) => {
    // Bound long-running server memory. Eviction loses recovery preferences only.
    sessions.delete(sessionID);
    sessions.set(sessionID, state);
    if (sessions.size > 1000) sessions.delete(sessions.keys().next().value!);
  };
  await ctx.model.transform(editor => {
    const primary = Model.Ref.parse(config.primary_model);
    const model = editor.get(primary.providerID, primary.id);
    if (model?.enabled && model.capabilities.tools)
      editor.default.set(primary.providerID, primary.id);
  });
  await ctx.session.hook("prompt", async event => {
    const session = await ctx.session.get({ sessionID: event.sessionID });
    const selected = session.model ?? (await ctx.model.default()).data;
    if (!selected || !chain.includes(key(selected))) {
      sessions.delete(event.sessionID);
      return;
    }
    const previous = sessions.get(event.sessionID);
    const origin = previous && same(previous.selected, selected) ? previous.origin : selected;
    const state: State = { origin, selected, attempts: 0, primary: false };
    const models = await available();
    // Recover only at a new user prompt, preserving an explicit/manual selection.
    const desired = ready(key(origin)) && models.has(key(origin)) ? origin :
      chain.slice(chain.indexOf(key(origin))).filter(id => ready(id) && models.has(id)).map(Model.Ref.parse)[0];
    if (desired && !same(desired, selected)) {
      await ctx.session.switchModel({ sessionID: event.sessionID, model: desired });
      state.selected = desired;
      notify(`${key(selected)} -> ${key(desired)} (prompt/cooldown)`);
    }
    remember(event.sessionID, state);
  });
  await ctx.session.hook("context", event => {
    const previous = sessions.get(event.sessionID);
    if (!chain.includes(key(event.model))) {
      sessions.delete(event.sessionID);
      return;
    }
    if (previous && same(previous.selected, event.model)) previous.primary = true;
    else remember(event.sessionID, { origin: event.model, selected: event.model, attempts: 0, primary: true });
  });
  // Compaction uses a fixed model internally; switching it here would not reroute
  // the compaction request. Leave its retry/overflow recovery to OpenCode.
  await ctx.session.hook("compaction", event => {
    const state = sessions.get(event.sessionID);
    if (state) state.primary = false;
  });
  await ctx.session.hook("retry", async event => {
    const state = sessions.get(event.sessionID);
    if (!state?.primary || !same(state.selected, event.model) || !fallbackError(event.error)) return;
    const session = await ctx.session.get({ sessionID: event.sessionID });
    if (session.model && !same(session.model, event.model)) return;
    cooldown.set(key(event.model), now() + config.cooldown_seconds * 1000);
    const models = await available();
    const next = chain.slice(chain.indexOf(key(event.model)) + 1).find(id => ready(id) && models.has(id));
    if (!next || state.attempts >= config.max_fallback_attempts) {
      event.decision = { retry: false };
      notify("Fallback chain exhausted; select a model or retry after cooldown.");
      return;
    }
    const model = Model.Ref.parse(next);
    await ctx.session.switchModel({ sessionID: event.sessionID, model });
    state.selected = model;
    state.attempts++;
    event.decision = { retry: true, delay: 0 };
    notify(`${key(event.model)} -> ${next} (${event.error.status ?? event.error.type})`);
  });
}

export default Plugin.define({
  id: "dotfiles.model-fallback",
  async setup(ctx) {
    const config = await loadConfig(ctx.location.directory);
    if (config) await setupFallback(ctx, config);
  },
});
