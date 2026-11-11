import type { Plugin } from "@opencode/plugin";
import { execFile } from "node:child_process";
import { mkdirSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import path from "node:path";

// Publishes each session's busy/idle/waiting state in the generic agent status
// directory read by SketchyBar's agents widget (see sketchybar/README.md).

export type AgentStatus = "busy" | "idle" | "waiting";

type StatusEvent = { type?: unknown; data?: unknown; location?: { directory?: unknown } };

export function statusDirectory(env: NodeJS.ProcessEnv = process.env): string {
  return path.join(env.XDG_STATE_HOME || path.join(homedir(), ".local/state"), "agents");
}

/** Maps an OpenCode event to a session status, `null` for removal, or nothing. */
export function statusFor(event: StatusEvent):
  | { sessionID: string; status: AgentStatus | null }
  | undefined {
  const data = event.data as Record<string, unknown> | undefined;
  const sessionID = data?.sessionID;
  if (typeof sessionID !== "string" || sessionID === "") return;
  switch (event.type) {
    case "session.status": {
      const type = (data?.status as { type?: unknown } | undefined)?.type;
      if (type === "busy" || type === "retry") return { sessionID, status: "busy" };
      if (type === "idle") return { sessionID, status: "idle" };
      return;
    }
    case "session.idle":
      return { sessionID, status: "idle" };
    case "permission.asked":
      return { sessionID, status: "waiting" };
    case "permission.replied":
      return { sessionID, status: "busy" };
    case "session.deleted":
      return { sessionID, status: null };
  }
}

export function fileFor(directory: string, sessionID: string): string {
  return path.join(directory, `opencode-${sessionID.replace(/[^A-Za-z0-9_-]/g, "_")}.json`);
}

export function writeStatus(
  directory: string,
  sessionID: string,
  status: AgentStatus,
  name: string,
  pid = process.pid,
): string {
  mkdirSync(directory, { recursive: true, mode: 0o700 });
  const file = fileFor(directory, sessionID);
  const temporary = `${file}.${pid}.tmp`;
  const record = { agent: "opencode", id: sessionID, pid, name, status, updated: Date.now() };
  writeFileSync(temporary, JSON.stringify(record), { mode: 0o600 });
  renameSync(temporary, file);
  return file;
}

function notify() {
  // SketchyBar also polls, so a missing binary only delays the update.
  execFile("sketchybar", ["--trigger", "agents_changed"], {
    env: { ...process.env, PATH: `/opt/homebrew/bin:/usr/local/bin:${process.env.PATH ?? ""}` },
    timeout: 2000,
  }, () => {});
}

export default {
  id: "dotfiles.agent-status",
  async setup(ctx) {
    const directory = statusDirectory();
    const written = new Map<string, AgentStatus>();
    let warned = false;
    const fallbackName = path.basename(String(ctx.location.directory));

    process.once("exit", () => {
      for (const sessionID of written.keys()) rmSync(fileFor(directory, sessionID), { force: true });
    });

    void (async () => {
      try {
        for await (const event of ctx.event.subscribe()) {
          const update = statusFor(event as StatusEvent);
          if (!update || written.get(update.sessionID) === update.status) continue;
          if (update.status === null && !written.has(update.sessionID)) continue;
          try {
            if (update.status === null) {
              written.delete(update.sessionID);
              rmSync(fileFor(directory, update.sessionID), { force: true });
            } else {
              const where = (event as StatusEvent).location?.directory;
              const name = typeof where === "string" ? path.basename(where) : fallbackName;
              writeStatus(directory, update.sessionID, update.status, name);
              written.set(update.sessionID, update.status);
            }
            notify();
          } catch (error) {
            if (!warned) console.warn("[agent-status] cannot write", directory, error);
            warned = true;
          }
        }
      } catch (error) {
        console.warn("[agent-status] event stream ended; SketchyBar status is stale", error);
      }
    })();
  },
} satisfies Plugin.Plugin;
