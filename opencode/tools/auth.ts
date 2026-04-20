import { tool } from "@opencode-ai/plugin";
import { execa, execaSync } from "execa";
import { existsSync, writeFileSync, unlinkSync, readFileSync, statSync, mkdirSync } from "fs";
import { join, resolve } from "path";

const LOCK_TIMEOUT_MS = 120_000; // 2 minutes max wait
const LOCK_STALE_MS = 180_000; // 3 minutes before considering a lock stale
const POLL_INTERVAL_MS = 2_000;

/**
 * Resolve the main worktree root from any worktree (or the main repo itself).
 * `git rev-parse --git-common-dir` returns the shared .git dir; its parent is the main worktree.
 */
function mainWorktreeRoot(cwd: string): string {
  const { stdout } = execaSync("git", ["rev-parse", "--git-common-dir"], { cwd });
  // stdout is an absolute or relative path to the common .git dir
  const gitCommonDir = resolve(cwd, stdout.trim());
  // The main worktree is the parent of the .git dir
  return resolve(gitCommonDir, "..");
}

function authStatePath(root: string): string {
  return join(root, "apps/playwright-tests/.auth/dev.json");
}

function lockFilePath(root: string): string {
  return join(root, ".opencode/.auth-lock");
}

function isLockStale(lockPath: string): boolean {
  try {
    const stat = statSync(lockPath);
    return Date.now() - stat.mtimeMs > LOCK_STALE_MS;
  } catch {
    return true;
  }
}

async function waitForLock(lockPath: string): Promise<void> {
  const start = Date.now();
  while (existsSync(lockPath) && !isLockStale(lockPath)) {
    if (Date.now() - start > LOCK_TIMEOUT_MS) {
      throw new Error("Timed out waiting for auth lock to release");
    }
    await new Promise((r) => setTimeout(r, POLL_INTERVAL_MS));
  }
}

function isAuthStateValid(statePath: string): boolean {
  try {
    if (!existsSync(statePath)) return false;
    const stat = statSync(statePath);
    // Consider auth state valid if it's less than 30 minutes old
    if (Date.now() - stat.mtimeMs > 30 * 60 * 1000) return false;
    const content = readFileSync(statePath, "utf-8");
    const parsed = JSON.parse(content);
    return parsed && typeof parsed === "object" && Object.keys(parsed).length > 0;
  } catch {
    return false;
  }
}

export const auth = tool({
  description: "Auth to skyon",
  args: {
    password: tool.schema.literal("SKYON_PASSWORD"),
    username: tool.schema.literal("SKYON_USERNAME"),
  },
  async execute(args, context) {
    const root = mainWorktreeRoot(context.directory);
    const statePath = authStatePath(root);
    const lockPath = lockFilePath(root);

    // If valid auth state already exists, skip re-authentication
    if (isAuthStateValid(statePath)) {
      return `Auth state already valid at ${statePath}`;
    }

    // Wait for any existing lock to release
    await waitForLock(lockPath);

    // After waiting, check again -- another executor may have completed auth
    if (isAuthStateValid(statePath)) {
      return `Auth state already valid at ${statePath} (completed by another executor)`;
    }

    // Acquire lock
    try {
      writeFileSync(lockPath, JSON.stringify({ pid: process.pid, ts: Date.now() }));
    } catch {
      // Lock dir may not exist yet
      const { mkdirSync } = await import("fs");
      mkdirSync(join(root, ".opencode"), { recursive: true });
      writeFileSync(lockPath, JSON.stringify({ pid: process.pid, ts: Date.now() }));
    }

    try {
      const result = await execa(
        "secrets",
        [
          "with",
          `${args.password}`,
          `${args.username}`,
          "--",
          "pnpm",
          "-C",
          "apps/playwright-tests",
          "test",
          "setup.spec.ts",
        ],
        {
          cwd: root,
          reject: false,
        },
      );

      return [result.stdout, result.stderr].filter(Boolean).join("\n");
    } finally {
      // Release lock
      try {
        unlinkSync(lockPath);
      } catch {
        // ignore cleanup errors
      }
    }
  },
});
