import { tool } from "@opencode-ai/plugin";
import { spawn } from "node:child_process";

async function run(args: string[] = [], cwd?: string) {
  return await new Promise<string>((resolve, reject) => {
    const child = spawn("rust-script", ["repo", ...args], {
      env: process.env,
      cwd: cwd || process.cwd(),
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

export const index = tool({
  description:
    "Indexes the current repository's files, modules, dependencies, entrypoints, and data-testids into a DuckDB database. Use when asked to index, scan, or catalog a repo, or before using repo_query for the first time.",
  args: {},
  async execute() {
    const result = await run(["index"]);
    return result || "Index complete.";
  },
});

export const query = tool({
  description:
    "Queries the DuckDB repo index with SQL to answer questions about repository structure, modules, dependencies, entrypoints, and data-testids. Run repo_index first if the index does not exist.",
  args: {
    sql: tool.schema.string().describe("SQL query to run against repos.duckdb"),
  },
  async execute(args) {
    const result = await run(["query", args.sql]);
    return result || "(no rows)";
  },
});

export const search = tool({
  description:
    "Full-text search across indexed repository chunks. Use keywords, function names, config names, or short phrases — not full sentences. Returns file paths, line ranges, descriptions, and snippets ranked by relevance. Run repo_index first if the index does not exist.",
  args: {
    query: tool.schema
      .string()
      .describe("Search query (use keywords, not full sentences)"),
    limit: tool.schema
      .number()
      .optional()
      .describe("Maximum number of results (default 20)"),
  },
  async execute(args) {
    const result = await run([
      "search",
      args.query,
      "--limit",
      String(args.limit ?? 20),
    ]);
    return result || "No results found.";
  },
});
