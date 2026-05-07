import { tool } from "@opencode-ai/plugin";
import { homedir } from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";

const scriptPath = path.join(homedir(), ".dotfiles", "bin", "learnings_store");

async function run(args: string[]) {
  return await new Promise<string>((resolve, reject) => {
    const child = spawn("python3", [scriptPath, ...args], {
      env: process.env,
      stdio: ["pipe", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";

    child.stdout.on("data", (chunk) => {
      stdout += chunk.toString();
    });
    child.stderr.on("data", (chunk) => {
      stderr += chunk.toString();
    });
    child.on("error", reject);
    child.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(stderr || stdout || `exited with ${code}`));
        return;
      }
      resolve(stdout);
    });
    child.stdin.end();
  });
}

function parseOutput(raw: string): string {
  try {
    return JSON.stringify(JSON.parse(raw), null, 2);
  } catch {
    return raw || "ok";
  }
}

export const init = tool({
  description: "Initialize the learnings SQLite database",
  args: {},
  async execute() {
    return parseOutput(await run(["init"]));
  },
});

export const query = tool({
  description:
    "Query agent learnings about the codebase, navigation, tools, and debugging. Supports full-text search, category filter, tag filter, and recent.",
  args: {
    search: tool.schema.string().optional().describe("Full-text search query"),
    category: tool.schema
      .enum([
        "navigation",
        "tool-usage",
        "codebase",
        "gotcha",
        "fixture",
        "selector",
        "debugging",
      ])
      .optional()
      .describe("Filter by category"),
    tags: tool.schema
      .string()
      .optional()
      .describe("Comma-separated tags to filter by (AND)"),
    recent: tool.schema
      .number()
      .optional()
      .describe("Show N most recent learnings"),
    limit: tool.schema.number().optional().describe("Max results (default 20)"),
  },
  async execute(args) {
    const cmd = ["query"];
    if (args.search) cmd.push("--search", args.search);
    if (args.category) cmd.push("--category", args.category);
    if (args.tags) cmd.push("--tags", args.tags);
    if (typeof args.recent === "number")
      cmd.push("--recent", String(args.recent));
    if (typeof args.limit === "number") cmd.push("--limit", String(args.limit));
    return parseOutput(await run(cmd));
  },
});

export const add = tool({
  description:
    "Record a new learning. Only use after implementation experience (regression-writer agent).",
  args: {
    category: tool.schema.enum([
      "navigation",
      "tool-usage",
      "codebase",
      "gotcha",
      "fixture",
      "selector",
      "debugging",
    ]),
    summary: tool.schema
      .string()
      .describe("Short description (under 100 chars)"),
    detail: tool.schema.string().optional().describe("Longer explanation"),
    tags: tool.schema.string().optional().describe("Comma-separated tags"),
    plan_id: tool.schema.string().optional().describe("Associated plan ID"),
    agent: tool.schema
      .string()
      .optional()
      .describe("Agent name (default: regression-writer)"),
  },
  async execute(args) {
    const cmd = ["add", "--category", args.category, "--summary", args.summary];
    if (args.detail) cmd.push("--detail", args.detail);
    if (args.tags) cmd.push("--tags", args.tags);
    if (args.plan_id) cmd.push("--plan-id", args.plan_id);
    if (args.agent) cmd.push("--agent", args.agent);
    return parseOutput(await run(cmd));
  },
});
