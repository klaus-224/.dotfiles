#!/usr/bin/env node

import { spawnSync, SpawnSyncOptions } from "node:child_process";

type Creds = {
  username: string;
  password: string;
};

function usage(): never {
  console.error(
    [
      "Usage:",
      "  auth-tool get <site>",
      "  auth-tool exec <site> -- <command> [args...]",
      "",
      "Examples:",
      "  auth-tool get example.com",
      "  auth-tool exec example.com -- pnpm tsx scripts/login.ts",
    ].join("\n"),
  );
  process.exit(1);
}

function runSecurity(service: string): string {
  const result = spawnSync(
    "security",
    ["find-generic-password", "-a", process.env.USER ?? "", "-s", service, "-w"],
    {
      encoding: "utf8",
    },
  );

  if (result.status !== 0) {
    const stderr = result.stderr?.trim() || `failed to read service: ${service}`;
    throw new Error(stderr);
  }

  return result.stdout.trim();
}

function getCreds(site: string): Creds {
  const usernameService = `website/${site}/username`;
  const passwordService = `website/${site}/password`;

  return {
    username: runSecurity(usernameService),
    password: runSecurity(passwordService),
  };
}

function execWithCreds(site: string, command: string, args: string[]): never {
  const creds = getCreds(site);

  const env = {
    ...process.env,
    WEBSITE_USERNAME: creds.username,
    WEBSITE_PASSWORD: creds.password,
  };

  const options: SpawnSyncOptions = {
    stdio: "inherit",
    env,
    encoding: "utf8",
  };

  const result = spawnSync(command, args, options);

  if (result.error) {
    console.error(result.error.message);
    process.exit(1);
  }

  process.exit(result.status ?? 1);
}

function main(): void {
  const [, , mode, site, ...rest] = process.argv;

  if (!mode || !site) usage();

  if (mode === "get") {
    const creds = getCreds(site);
    process.stdout.write(`${JSON.stringify(creds, null, 2)}\n`);
    return;
  }

  if (mode === "exec") {
    const sep = rest.indexOf("--");
    if (sep === -1) {
      console.error("Missing `--` before command");
      usage();
    }

    const cmdParts = rest.slice(sep + 1);
    const [command, ...args] = cmdParts;

    if (!command) {
      console.error("Missing command to execute");
      usage();
    }

    execWithCreds(site, command, args);
  }

  usage();
}

main();
