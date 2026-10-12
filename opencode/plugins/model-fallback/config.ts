import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";
import { parse, type ParseError } from "jsonc-parser";
import { Model } from "@opencode/plugin";

export interface FallbackConfig {
  enabled: boolean;
  primary_model: string;
  fallback_models: string[];
  cooldown_seconds: number;
  max_fallback_attempts: number;
  timeout_seconds: 0;
  notify_on_fallback: boolean;
}

export function parseConfig(text: string): FallbackConfig {
  const errors: ParseError[] = [];
  const config = parse(text, errors, { allowTrailingComma: true });
  if (errors.length || !config || typeof config !== "object" || Array.isArray(config))
    throw new Error("Invalid model fallback JSONC");
  const keys = ["enabled", "primary_model", "fallback_models", "cooldown_seconds",
    "max_fallback_attempts", "timeout_seconds", "notify_on_fallback"];
  if (Object.keys(config).some(key => !keys.includes(key)) ||
    typeof config.enabled !== "boolean" || typeof config.notify_on_fallback !== "boolean" ||
    typeof config.primary_model !== "string" || !Array.isArray(config.fallback_models) ||
    !config.fallback_models.every((id: unknown) => typeof id === "string") ||
    !Number.isFinite(config.cooldown_seconds) || config.cooldown_seconds < 0 ||
    !Number.isInteger(config.max_fallback_attempts) || config.max_fallback_attempts < 0 ||
    config.max_fallback_attempts > 4 || config.timeout_seconds !== 0)
    throw new Error("Invalid model fallback settings (at most four attempts; timeouts must be disabled)");
  const chain = [config.primary_model, ...config.fallback_models] as string[];
  for (const id of chain) Model.Ref.parse(id);
  if (new Set(chain).size !== chain.length || chain.some(id => id.includes("#") || /\s/.test(id)))
    throw new Error("Fallback models must be distinct real model references without variants");
  return config;
}

// Project configuration replaces the global policy. Missing config disables routing.
export async function loadConfig(directory: string, env = process.env): Promise<FallbackConfig | undefined> {
  const global = env.OPENCODE_CONFIG_DIR || join(env.XDG_CONFIG_HOME || join(homedir(), ".config"), "opencode");
  for (const base of [join(directory, ".opencode"), global]) {
    for (const name of ["opencode-fallback.jsonc", "opencode-fallback.json"]) {
      let text: string;
      try { text = await readFile(join(base, name), "utf8"); }
      catch (error) {
        if ((error as NodeJS.ErrnoException).code === "ENOENT") continue;
        throw error;
      }
      return parseConfig(text);
    }
  }
}
