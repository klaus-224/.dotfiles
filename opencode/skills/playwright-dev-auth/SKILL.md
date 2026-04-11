---
name: playwright-dev-auth
description: Generate or refresh the shared Playwright auth state from apps/playwright-tests/setup.spec.ts for manual testing
compatibility: opencode
---

## When to use

- Before manual Jira ticket testing that depends on a logged-in browser session
- When `apps/playwright-tests/.auth/dev.json` is missing, stale, or invalid

## What to do

1. First confirm whether `apps/playwright-tests/.auth/dev.json` already exists.
2. If the auth file already exists and the user did not explicitly ask for a refresh, you may report it as available instead of re-running login.
3. When a refresh is needed, run the repository's Playwright setup test from the repo root or from `apps/playwright-tests/`.
4. Prefer the existing `secrets` wrapper when auth depends on keychain-backed env injection. Run only the setup spec:

   ```bash
   cd apps/playwright-tests
   secrets with ENV_VAR_NAME_1 ENV_VAR_NAME_2 pnpm playwright test setup.spec.ts
   ```

    **the only command for `secrets` is `with`**

5. Treat the run as successful only if it produces `apps/playwright-tests/.auth/dev.json`.
6. Do not print or inspect the auth file contents.

## Rules

- Treat `apps/playwright-tests/.auth/dev.json` as sensitive
- Never commit the auth file
- If the auth flow is interactive or requires MFA, tell the user immediately
- For recovery, rerun only the setup spec once; do not loop endlessly
- Return only status, whether auth was reused or refreshed, command used, and auth file path
