import { tool } from "@opencode-ai/plugin";
import { execa } from "execa";

export const auth = tool({
  description: "Auth to skyon",
  args: {
    password: tool.schema.literal("SKYON_PASSWORD"),
    username: tool.schema.literal("SKYON_USERNAME"),
  },
  async execute(args, context) {
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
        cwd: context.directory,
        reject: false,
      },
    );

    return [result.stdout, result.stderr].filter(Boolean).join("\n");
  },
});
