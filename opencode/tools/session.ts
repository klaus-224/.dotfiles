import { tool } from "@opencode-ai/plugin";
import { homedir } from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";

const scriptPath = path.join(homedir(), ".dotfiles", "bin", "session_reader");

async function run(args: string[]) {
	return await new Promise<string>((resolve, reject) => {
		const child = spawn(scriptPath, args, {
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

export const list = tool({
	description:
		"List OpenCode sessions from the local database. Useful for finding regression-related sessions to review.",
	args: {
		search: tool.schema
			.string()
			.optional()
			.describe("Search string to filter session titles (default: 'regress')"),
		limit: tool.schema
			.number()
			.optional()
			.describe("Max sessions to return (default 10)"),
	},
	async execute(args) {
		const cmd = ["list"];
		if (args.search) cmd.push("--search", args.search);
		if (typeof args.limit === "number") cmd.push("--limit", String(args.limit));
		return parseOutput(await run(cmd));
	},
});

export const transcript = tool({
	description:
		"Get the full transcript of an OpenCode session, showing agent reasoning, tool calls, and decisions.",
	args: {
		session_id: tool.schema.string().describe("The session ID to retrieve"),
	},
	async execute(args) {
		return parseOutput(await run(["transcript", args.session_id]));
	},
});
