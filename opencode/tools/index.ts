import { tool, ToolResult } from "@opencode-ai/plugin";
import { spawn } from "node:child_process";

const script = "project_index";

async function run(args: string[] = [], cwd?: string) {
  return await new Promise<string>((resolve, reject) => {
<<<<<<<< HEAD:opencode/tools/project_index.ts
    const child = spawn("project_index", [...args], {
|||||||| parent of 488a3ae (use project_index):opencode/tools/repo.ts
    const child = spawn("repo", [...args], {
========
    const child = spawn(script, [...args], {
>>>>>>>> 488a3ae (use project_index):opencode/tools/index.ts
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

export const help = tool({
  description:
<<<<<<<< HEAD:opencode/tools/project_index.ts
    "Prints help docs to stdout for project_index_query, repo_index, and repo_search",
|||||||| parent of 488a3ae (use project_index):opencode/tools/repo.ts
    "Prints help docs to stdout for repo_query, repo_index, and repo_search",
========
    "Prints help docs to stdout for project_index_query, project_index, and project_index_search",
>>>>>>>> 488a3ae (use project_index):opencode/tools/index.ts
  args: {
    category: tool.schema.enum([
<<<<<<<< HEAD:opencode/tools/project_index.ts
      "project_index_search",
      "repo_query",
      "repo_index",
|||||||| parent of 488a3ae (use project_index):opencode/tools/repo.ts
    category: tool.schema.enum(["repo_search", "repo_query", "repo_index"]),
========
      "project_index_index",
      "project_index_querj",
      "project_index_search",
>>>>>>>> 488a3ae (use project_index):opencode/tools/index.ts
    ]),
  },
  execute: function (args): Promise<ToolResult> {
    const result = run([args.category, "--help"]);
    return result;
  },
});

export const index = tool({
  description:
<<<<<<<< HEAD:opencode/tools/project_index.ts
    "Indexes the current project_indexsitory's files, modules, dependencies, entrypoints, and data-testids into a DuckDB database. Use when asked to index, scan, or catalog a repo, or before using repo_query for the first time.",
|||||||| parent of 488a3ae (use project_index):opencode/tools/repo.ts
    "Indexes the current repository's files, modules, dependencies, entrypoints, and data-testids into a DuckDB database. Use when asked to index, scan, or catalog a repo, or before using repo_query for the first time.",
========
    "Indexes the current project_indexsitory's files, modules, dependencies, entrypoints, and data-testids into a DuckDB database. Use when asked to index, scan, or catalog a project, or before using project_index_query for the first time.",
>>>>>>>> 488a3ae (use project_index):opencode/tools/index.ts
  args: {},
  async execute() {
    const result = await run(["index"]);
    return result || "Index complete.";
  },
});

export const query = tool({
  description:
<<<<<<<< HEAD:opencode/tools/project_index.ts
    "Queries the DuckDB project_index index with SQL to answer questions about repository structure, modules, dependencies, entrypoints, and data-testids. Best used as a first pass before narrowing down using repo_search. Run repo_index first if the index does not exist.",
|||||||| parent of 488a3ae (use project_index):opencode/tools/repo.ts
    "Queries the DuckDB repo index with SQL to answer questions about repository structure, modules, dependencies, entrypoints, and data-testids. Best used as a first pass before narrowing down using repo_search. Run repo_index first if the index does not exist.",
========
    "Queries the DuckDB project_index index with SQL to answer questions about repository structure, modules, dependencies, entrypoints, and data-testids. Best used as a first pass before narrowing down using project_index_search. Run project_index first if the index does not exist.",
>>>>>>>> 488a3ae (use project_index):opencode/tools/index.ts
  args: {
    sql: tool.schema
      .string()
      .describe("SQL query to run against project_indexs.duckdb"),
  },
  async execute(args) {
    const result = await run(["query", args.sql]);
    return result || "(no rows)";
  },
});

export const search = tool({
  description:
<<<<<<<< HEAD:opencode/tools/project_index.ts
    "Full-text search across indexed project_indexsitory chunks. Use keywords, function names, config names, or short phrases — not full sentences. Returns file paths, line ranges, descriptions, and snippets ranked by relevance. Run repo_index first if the index does not exist.",
|||||||| parent of 488a3ae (use project_index):opencode/tools/repo.ts
    "Full-text search across indexed repository chunks. Use keywords, function names, config names, or short phrases — not full sentences. Returns file paths, line ranges, descriptions, and snippets ranked by relevance. Run repo_index first if the index does not exist.",
========
    "Full-text search across indexed project_indexsitory chunks. Use keywords, function names, config names, or short phrases — not full sentences. Returns file paths, line ranges, descriptions, and snippets ranked by relevance. Run project_index first if the index does not exist.",
>>>>>>>> 488a3ae (use project_index):opencode/tools/index.ts
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
