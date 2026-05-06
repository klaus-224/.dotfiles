import { tool } from "@opencode-ai/plugin";
import { homedir } from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";

const repoScript = path.join(homedir(), ".dotfiles", "bin", "repo");

async function run(args: string[] = [], cwd?: string) {
  return await new Promise<string>((resolve, reject) => {
    const child = spawn("uv", ["run", "--script", repoScript, ...args], {
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

export const repo_index = tool({
  description:
    "Indexes the current repository's files, modules, dependencies, entrypoints, and data-testids into a DuckDB database. Use when asked to index, scan, or catalog a repo, or before using repo_query for the first time.",
  args: {},
  async execute() {
    const result = await run(["index"]);
    return result || "Index complete.";
  },
});

export const repo_query = tool({
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
