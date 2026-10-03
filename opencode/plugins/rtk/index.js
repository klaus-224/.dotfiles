import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

// OpenCode v2 adapter for https://github.com/rtk-ai/rtk/tree/master/hooks/opencode.
// Keep command parsing in `rtk rewrite`; never interpolate commands into a shell.
export default {
  id: 'dotfiles.rtk',
  async setup(ctx) {
    let warned = false;
    await ctx.shell.hook('create.before', async (event) => {
      if (!event.command.trim()) return;
      try {
        const { stdout } = await execFileAsync(
          'rtk',
          ['rewrite', event.command],
          {
            cwd: event.cwd,
            env: event.env,
            timeout: 2000,
            maxBuffer: 1024 * 1024,
            encoding: 'utf8'
          }
        );
        const rewritten = stdout.trim();
        if (rewritten) event.command = rewritten;
      } catch (error) {
        // RTK 0.50 also returns valid rewrites with exit 3: keep the host's
        // normal permission evaluation. Exit 0 must not auto-approve either.
        if (error.code === 3 && error.stdout?.trim()) {
          event.command = error.stdout.trim();
          return;
        }
        // Exit 1 means unsupported; exit 2 defers a denial to the host.
        if (
          (error.code === 1 || error.code === 2) &&
          !error.stdout &&
          !error.stderr
        )
          return;
        // A missing/broken RTK must not prevent the original command from running.
        if (!warned) {
          console.warn(
            '[rtk] rewrite unavailable; using original shell commands'
          );
          warned = true;
        }
      }
    });
  }
};
