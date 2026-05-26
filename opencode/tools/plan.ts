import { tool } from "@opencode-ai/plugin";
import { homedir } from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";

const scriptPath =
	process.env.OPENCODE_PLAN_STORE_BIN ??
	path.join(homedir(), ".dotfiles", "bin", "plan_store");

const pythonBin = process.env.OPENCODE_PLAN_STORE_PYTHON ?? "python3";

async function runPlanStore(args: string[], stdin?: string) {
	return await new Promise<string>((resolve, reject) => {
		const child = spawn(pythonBin, [scriptPath, ...args], {
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
				reject(new Error(stderr || stdout || `plan_store exited with ${code}`));
				return;
			}
			resolve(stdout);
		});

		if (stdin) {
			child.stdin.write(stdin);
		}
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
	description: "Initialize the SQLite plan store database",
	args: {},
	async execute() {
		return parseOutput(await runPlanStore(["init-db"]));
	},
});

export const create = tool({
	description: "Create a new collaborative plan shell",
	args: {
		task_key: tool.schema
			.string()
			.describe("Stable task key, e.g. feature/auth-refresh"),
		title: tool.schema.string().describe("Human-readable plan title"),
		agent: tool.schema.string().describe("Creating agent name, e.g. planner"),
		goal: tool.schema.string().describe("One-sentence goal for the plan"),
	},
	async execute(args) {
		return parseOutput(
			await runPlanStore([
				"create",
				"--task-key",
				args.task_key,
				"--title",
				args.title,
				"--agent",
				args.agent,
				"--goal",
				args.goal,
			]),
		);
	},
});

export const get = tool({
	description: "Fetch a plan, its selected version, and comments",
	args: {
		plan_id: tool.schema.string(),
		version: tool.schema.number().optional(),
		approved: tool.schema.boolean().optional(),
	},
	async execute(args) {
		const cmd = ["get", "--plan-id", args.plan_id];
		if (typeof args.version === "number") {
			cmd.push("--version", String(args.version));
		}
		if (args.approved) {
			cmd.push("--approved");
		}
		return parseOutput(await runPlanStore(cmd));
	},
});

export const list = tool({
	description: "List plans by optional state or owner",
	args: {
		state: tool.schema.string().optional(),
		owner_agent: tool.schema.string().optional(),
	},
	async execute(args) {
		const cmd = ["list"];
		if (args.state) {
			cmd.push("--state", args.state);
		}
		if (args.owner_agent) {
			cmd.push("--owner-agent", args.owner_agent);
		}
		return parseOutput(await runPlanStore(cmd));
	},
});

export const claim = tool({
	description: "Claim a lease on a plan before revising it",
	args: {
		plan_id: tool.schema.string(),
		agent: tool.schema.string(),
		ttl: tool.schema.number().optional(),
	},
	async execute(args) {
		const cmd = ["claim", "--plan-id", args.plan_id, "--agent", args.agent];
		if (typeof args.ttl === "number") {
			cmd.push("--ttl", String(args.ttl));
		}
		return parseOutput(await runPlanStore(cmd));
	},
});

export const release = tool({
	description: "Release a lease after plan work is complete",
	args: {
		plan_id: tool.schema.string(),
		agent: tool.schema.string(),
	},
	async execute(args) {
		return parseOutput(
			await runPlanStore([
				"release",
				"--plan-id",
				args.plan_id,
				"--agent",
				args.agent,
			]),
		);
	},
});

export const revise = tool({
	description: "Create a new immutable plan version from canonical JSON",
	args: {
		plan_id: tool.schema.string(),
		agent: tool.schema.string(),
		change_note: tool.schema.string(),
		state: tool.schema.string().optional(),
		plan_json: tool.schema
			.string()
			.describe("Canonical JSON object as a string"),
	},
	async execute(args) {
		const cmd = [
			"revise",
			"--plan-id",
			args.plan_id,
			"--agent",
			args.agent,
			"--change-note",
			args.change_note,
			"--stdin",
		];
		if (args.state) {
			cmd.push("--state", args.state);
		}
		return parseOutput(await runPlanStore(cmd, args.plan_json));
	},
});

export const comment = tool({
	description: "Attach a review or blocker comment to a plan version",
	args: {
		plan_id: tool.schema.string(),
		version: tool.schema.number().optional(),
		agent: tool.schema.string(),
		comment_type: tool.schema.enum(["review", "blocker", "suggestion", "note"]),
		body: tool.schema.string(),
	},
	async execute(args) {
		const cmd = [
			"comment",
			"--plan-id",
			args.plan_id,
			"--agent",
			args.agent,
			"--comment-type",
			args.comment_type,
			"--body",
			args.body,
		];
		if (typeof args.version === "number") {
			cmd.push("--version", String(args.version));
		}
		return parseOutput(await runPlanStore(cmd));
	},
});

export const transition = tool({
	description:
		"Move a plan between drafting, reviewing, approved, executing, done, or abandoned",
	args: {
		plan_id: tool.schema.string(),
		agent: tool.schema.string(),
		state: tool.schema.enum([
			"drafting",
			"reviewing",
			"approved",
			"executing",
			"done",
			"abandoned",
		]),
		owner_agent: tool.schema.string(),
		require_lease: tool.schema.boolean().optional(),
	},
	async execute(args) {
		const cmd = [
			"transition",
			"--plan-id",
			args.plan_id,
			"--agent",
			args.agent,
			"--state",
			args.state,
			"--owner-agent",
			args.owner_agent,
		];
		if (args.require_lease) {
			cmd.push("--require-lease");
		}
		return parseOutput(await runPlanStore(cmd));
	},
});

export const approve = tool({
	description: "Mark a version as the approved execution handoff",
	args: {
		plan_id: tool.schema.string(),
		agent: tool.schema.string(),
		version: tool.schema.number().optional(),
		require_lease: tool.schema.boolean().optional(),
	},
	async execute(args) {
		const cmd = ["approve", "--plan-id", args.plan_id, "--agent", args.agent];
		if (typeof args.version === "number") {
			cmd.push("--version", String(args.version));
		}
		if (args.require_lease) {
			cmd.push("--require-lease");
		}
		return parseOutput(await runPlanStore(cmd));
	},
});

export const render = tool({
	description:
		"Render a markdown view of a plan version for a disposable handoff file",
	args: {
		plan_id: tool.schema.string(),
		agent: tool.schema.string().optional(),
		version: tool.schema.number().optional(),
		approved: tool.schema.boolean().optional(),
		out: tool.schema.string().optional(),
	},
	async execute(args) {
		const cmd = ["render", "--plan-id", args.plan_id];
		if (args.agent) {
			cmd.push("--agent", args.agent);
		}
		if (typeof args.version === "number") {
			cmd.push("--version", String(args.version));
		}
		if (args.approved) {
			cmd.push("--approved");
		}
		if (args.out) {
			cmd.push("--out", args.out);
		}
		return parseOutput(await runPlanStore(cmd));
	},
});
