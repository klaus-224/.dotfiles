import { tool } from "@opencode-ai/plugin";
import { spawn } from "node:child_process";

type PullRequest = {
  baseRefName: string;
  baseRefOid: string;
  changedFiles: number;
  headRefName: string;
  headRefOid: string;
  isCrossRepository: boolean;
  number: number;
  title: string;
  url: string;
};

type PullRequestFile = {
  additions: number;
  changes: number;
  deletions: number;
  path: string;
  patch?: string | null;
  previous_filename?: string | null;
  sha: string;
  status: string;
};

const MAX_OUTPUT_BYTES = 4 * 1024 * 1024;
const MAX_PATCH_CHARS = 20_000;
const MAX_TOTAL_PATCH_CHARS = 1_000_000;
const TIMEOUT_MS = 60_000;
const VALID_TYPES = new Set(["manual", "unit", "playwright"]);

export function parseTestTypes(input: string): string[] {
  const values = input
    .split(",")
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean);

  if (values.length === 0 || values.some((value) => !VALID_TYPES.has(value))) {
    throw new Error(
      "test_types must be a comma-separated set containing only manual, unit, or playwright",
    );
  }

  return [...new Set(values)];
}

export function parseSource(source: string): {
  number: number;
  repository?: string;
} {
  const value = source.trim();
  if (/^[1-9]\d*$/.test(value)) {
    const number = Number(value);
    if (!Number.isSafeInteger(number)) {
      throw new Error("pull request number is too large");
    }
    return { number };
  }

  let url: URL;
  try {
    url = new URL(value);
  } catch {
    throw new Error("source must be a positive PR number or a GitHub PR URL");
  }

  const parts = url.pathname.split("/").filter(Boolean);
  if (
    url.protocol !== "https:" ||
    url.hostname.toLowerCase() !== "github.com" ||
    url.username !== "" ||
    url.password !== "" ||
    url.port !== "" ||
    url.search !== "" ||
    url.hash !== "" ||
    parts.length !== 4 ||
    parts[2] !== "pull" ||
    !/^[A-Za-z0-9-]+$/.test(parts[0]) ||
    !/^[A-Za-z0-9._-]+$/.test(parts[1]) ||
    !/^[1-9]\d*$/.test(parts[3])
  ) {
    throw new Error(
      "source must match https://github.com/<owner>/<repo>/pull/<number>",
    );
  }

  const number = Number(parts[3]);
  if (!Number.isSafeInteger(number)) {
    throw new Error("pull request number is too large");
  }

  return {
    number,
    repository: `${parts[0]}/${parts[1]}`,
  };
}

async function runGh(
  args: string[],
  cwd: string,
  signal: AbortSignal,
): Promise<string> {
  return await new Promise<string>((resolve, reject) => {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
    const abort = () => controller.abort();
    signal.addEventListener("abort", abort, { once: true });

    const child = spawn("gh", args, {
      cwd,
      env: process.env,
      signal: controller.signal,
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";
    let outputBytes = 0;
    let overflow = false;
    let settled = false;

    const cleanup = () => {
      clearTimeout(timeout);
      signal.removeEventListener("abort", abort);
    };
    const succeed = (value: string) => {
      if (settled) return;
      settled = true;
      cleanup();
      resolve(value);
    };
    const fail = (error: Error) => {
      if (settled) return;
      settled = true;
      cleanup();
      reject(error);
    };

    const collect = (target: "stdout" | "stderr", chunk: Buffer) => {
      outputBytes += chunk.length;
      if (outputBytes > MAX_OUTPUT_BYTES) {
        overflow = true;
        controller.abort();
        return;
      }
      if (target === "stdout") stdout += chunk.toString();
      else stderr += chunk.toString();
    };

    child.stdout.on("data", (chunk: Buffer) => collect("stdout", chunk));
    child.stderr.on("data", (chunk: Buffer) => collect("stderr", chunk));
    child.on("error", (error) => {
      if (overflow) fail(new Error("gh output exceeded the 4 MiB limit"));
      else if (signal.aborted) fail(new Error("PR context request cancelled"));
      else if (controller.signal.aborted)
        fail(new Error(`gh timed out after ${TIMEOUT_MS / 1000} seconds`));
      else fail(error);
    });
    child.on("close", (code) => {
      if (overflow) {
        fail(new Error("gh output exceeded the 4 MiB limit"));
        return;
      }
      if (code !== 0) {
        fail(new Error(stderr.trim() || `gh exited with status ${code}`));
        return;
      }
      succeed(stdout);
    });
  });
}

function parseJson<T>(raw: string, label: string): T {
  try {
    return JSON.parse(raw) as T;
  } catch (error) {
    throw new Error(
      `${label} returned invalid JSON: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

export const get = tool({
  description:
    "Resolve a GitHub pull request and return metadata, the complete changed-file inventory, patches when available, and explicit completeness markers. Read-only.",
  args: {
    source: tool.schema
      .string()
      .describe("Positive PR number or full GitHub pull request URL"),
    test_types: tool.schema
      .string()
      .describe("Comma-separated set of manual, unit, and/or playwright"),
  },
  async execute(args, context) {
    const selectedTypes = parseTestTypes(args.test_types);
    const source = parseSource(args.source);
    const prRef = String(source.number);
    const repoArgs = source.repository ? ["--repo", source.repository] : [];

    const metadataRaw = await runGh(
      [
        "pr",
        "view",
        prRef,
        ...repoArgs,
        "--json",
        "number,title,url,baseRefName,baseRefOid,changedFiles,headRefName,headRefOid,isCrossRepository",
      ],
      context.directory,
      context.abort,
    );
    const metadata = parseJson<PullRequest>(metadataRaw, "gh pr view");

    const repository = parseSource(metadata.url).repository;
    if (!repository) {
      throw new Error("GitHub did not return the pull request repository identity");
    }

    const pageSize = 100;
    const files: PullRequestFile[] = [];
    let page = 1;
    for (;;) {
      const filesRaw = await runGh(
        [
          "api",
          "-H",
          "Accept: application/vnd.github+json",
          `repos/${repository}/pulls/${metadata.number}/files?per_page=${pageSize}&page=${page}`,
        ],
        context.directory,
        context.abort,
      );
      const currentPage = parseJson<PullRequestFile[]>(
        filesRaw,
        `gh api PR files page ${page}`,
      );
      files.push(...currentPage);
      if (currentPage.length < pageSize) break;
      page += 1;
    }
    const filesWithoutPatches = files
      .filter((file) => !file.patch)
      .map((file) => file.path);
    let retainedPatchChars = 0;
    const filesWithTruncatedPatches: string[] = [];
    const changedFiles = files.map((file) => {
      const patch = file.patch ?? null;
      const remaining = Math.max(0, MAX_TOTAL_PATCH_CHARS - retainedPatchChars);
      const retainedLength = patch
        ? Math.min(patch.length, MAX_PATCH_CHARS, remaining)
        : 0;
      const retainedPatch = patch ? patch.slice(0, retainedLength) : null;
      retainedPatchChars += retainedLength;
      const patchTruncated = Boolean(patch && retainedLength < patch.length);
      if (patchTruncated) filesWithTruncatedPatches.push(file.path);

      return {
        path: file.path,
        previous_path: file.previous_filename ?? null,
        status: file.status,
        sha: file.sha,
        additions: file.additions,
        deletions: file.deletions,
        changes: file.changes,
        patch: retainedPatch,
        patch_available: Boolean(patch),
        patch_truncated_by_tool: patchTruncated,
      };
    });
    const inventoryComplete = files.length === metadata.changedFiles;
    const patchEvidenceComplete =
      inventoryComplete &&
      filesWithoutPatches.length === 0 &&
      filesWithTruncatedPatches.length === 0;
    const notes: string[] = [];
    if (!inventoryComplete) {
      notes.push(
        `GitHub reports ${metadata.changedFiles} changed files, but ${files.length} were retrieved. Treat the missing inventory as unresolved.`,
      );
    }
    if (filesWithoutPatches.length > 0) {
      notes.push(
        "GitHub omitted patches for one or more files. Common causes include binary files and oversized diffs; inspect those files from a matching checkout or mark them unresolved.",
      );
    }
    if (filesWithTruncatedPatches.length > 0) {
      notes.push(
        "The tool bounded large patch text to keep the result usable. Treat truncated patch evidence as incomplete and inspect the referenced files from a matching checkout.",
      );
    }
    notes.push(
      "GitHub's REST response does not prove that every returned patch is semantically complete; verify material files against the base/head revisions when possible.",
    );

    const result = {
      source: {
        repository,
        number: metadata.number,
        title: metadata.title,
        url: metadata.url,
        base: { ref: metadata.baseRefName, sha: metadata.baseRefOid },
        head: { ref: metadata.headRefName, sha: metadata.headRefOid },
        cross_repository: metadata.isCrossRepository,
      },
      allowed_test_types: selectedTypes,
      changed_files: changedFiles,
      completeness: {
        inventory_complete: inventoryComplete,
        reported_file_count: metadata.changedFiles,
        retrieved_file_count: files.length,
        page_count: page,
        patch_evidence_complete: patchEvidenceComplete,
        github_patch_completeness_guaranteed: false,
        files_without_patches: filesWithoutPatches,
        files_with_tool_truncated_patches: filesWithTruncatedPatches,
        checkout_context_available: !source.repository,
        notes,
      },
    };

    return {
      title: `PR #${metadata.number}: ${metadata.title}`,
      output: JSON.stringify(result, null, 2),
      metadata: {
        repository,
        pullRequest: metadata.number,
        fileCount: files.length,
        inventoryComplete,
        patchEvidenceComplete,
      },
    };
  },
});
