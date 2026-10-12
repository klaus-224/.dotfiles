// Isolated OpenCode 2.0.20 integration test. No account credentials or hosted inference.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { mkdtemp, mkdir, writeFile, rm } from 'node:fs/promises';
import { createServer } from 'node:http';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

async function check(status, exhausted = false) {
  const root = await mkdtemp(join(tmpdir(), 'opencode-fallback-runtime-'));
  const requests = [];
  let host;
  const server = createServer(async (req, res) => {
    const chunks = [];
    for await (const chunk of req) chunks.push(chunk);
    const body = JSON.parse(Buffer.concat(chunks).toString());
    if (!body.tools) {
      res.writeHead(200, { 'content-type': 'text/event-stream' });
      res.end('data: ' + JSON.stringify({ id: 'aux', object: 'chat.completion.chunk', created: 1, model: body.model, choices: [{ index: 0, delta: { content: 'Fixture' }, finish_reason: 'stop' }] }) + '\n\ndata: [DONE]\n\n');
      return;
    }
    requests.push(body);
    // Complete one tool call on primary, then simulate quota exhaustion on its
    // continuation. The backup must receive the completed tool result once.
    const hasResult = body.messages.some(m => m.role === 'tool');
    if ((body.model === 'primary' || exhausted) && hasResult) {
      res.writeHead(status, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ error: { message: status === 404 ? 'model not found' : 'quota exceeded', type: status === 404 ? 'model_not_found' : 'insufficient_quota' } }));
      return;
    }
    res.writeHead(200, { 'content-type': 'text/event-stream' });
    const send = (delta, finish_reason = null) => res.write(`data: ${JSON.stringify({
      id: 'fixture-response', object: 'chat.completion.chunk', created: 1, model: body.model,
      choices: [{ index: 0, delta, finish_reason }],
    })}\n\n`);
    if (!hasResult) {
      const tool = body.tools.find(t => t.function.name === 'fixture_mark');
      if (!tool) { send({ content: 'Missing fixture_mark: ' + body.tools.map(t => t.function.name).join(',') }, 'stop'); res.end('data: [DONE]\n\n'); return; }
      send({ role: 'assistant', tool_calls: [{ index: 0, id: 'mark-once', type: 'function', function: { name: 'fixture_mark', arguments: '{}' } }] });
      send({}, 'tool_calls');
    } else {
      send({ role: 'assistant', content: 'FALLBACK_OK' });
      send({}, 'stop');
    }
    res.end('data: [DONE]\n\n');
  });
  try {
    await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
    const baseURL = `http://127.0.0.1:${server.address().port}/v1`;
    const directory = join(root, 'project');
    const configDir = join(root, 'config/opencode');
    await mkdir(directory); await mkdir(configDir, { recursive: true });
    const fixturePlugin = join(root, 'fixture');
    await mkdir(fixturePlugin);
    await writeFile(join(fixturePlugin, 'package.json'), JSON.stringify({ name: 'fallback-fixture', type: 'module', exports: './index.js' }));
    const marker = join(root, 'marker');
    await writeFile(join(fixturePlugin, 'index.js'), `import { appendFile } from 'node:fs/promises';
  export default { id: 'fixture.tools', async setup(ctx) {
    await ctx.session.hook('title', event => { event.result = 'Fixture'; });
    await ctx.tool.transform(editor => {
      editor.namespace({ name: 'fixture', description: 'Test fixture' });
      editor.add({ name: 'mark', options: { namespace: 'fixture', codemode: false }, description: 'Record once',
        input: { type: 'object', properties: {}, additionalProperties: false },
        async execute() { await appendFile(${JSON.stringify(marker)}, 'once\\n'); return { content: 'MARKED_ONCE', metadata: {} }; }
      });
    });
  }};`);
    const plugin = fileURLToPath(new URL('../plugins/model-fallback', import.meta.url));
    const provider = { package: '@opencode/ai/providers/openai-compatible', settings: { baseURL, apiKey: 'local-fixture', transport: 'http' } };
    await writeFile(join(configDir, 'opencode.json'), JSON.stringify({
      plugins: [plugin, fixturePlugin], snapshots: false, update: 'disable',
      providers: {
        'fixture-primary': { ...provider, models: { primary: { limit: { context: 100000, output: 1000 } } } },
        'fixture-backup': { ...provider, models: Object.fromEntries(['backup', 'backup-2', 'backup-3', 'backup-4'].map(id => [id, { limit: { context: 100000, output: 1000 } }])) },
      },
      permissions: [{ action: '*', resource: '*', effect: 'deny' }, { action: 'fixture*', resource: '*', effect: 'allow' }],
      experimental: { policies: [{ action: 'provider.use', resource: '*', effect: 'deny' }, { action: 'provider.use', resource: 'fixture-*', effect: 'allow' }] },
    }));
    await writeFile(join(configDir, 'opencode-fallback.jsonc'), JSON.stringify({
      enabled: true, primary_model: 'fixture-primary/primary', fallback_models: ['backup', 'backup-2', 'backup-3', 'backup-4'].map(id => 'fixture-backup/' + id),
      cooldown_seconds: 300, max_fallback_attempts: 4, timeout_seconds: 0, notify_on_fallback: true,
    }));
    const env = { PATH: process.env.PATH, HOME: root, TMPDIR: tmpdir(),
      XDG_DATA_HOME: join(root, 'data'), XDG_CONFIG_HOME: join(root, 'config'), XDG_CACHE_HOME: join(root, 'cache'),
      XDG_STATE_HOME: join(root, 'state'), OPENCODE_CONFIG_DIR: configDir,
      OPENCODE_SERVER_PASSWORD: 'local-fixture-only', OPENCODE_TEST_HOME: root, OPENCODE_DISABLE_MODELS_FETCH: 'true', OPENCODE_DISABLE_FILEWATCHER: 'true', OPENCODE_DISABLE_FFF: 'true',
    };
    let hostLog = '';
    const serverURL = await new Promise((resolve, reject) => {
      host = spawn('opencode', ['serve', '--port', '0', '--print-logs'], { cwd: directory, env, detached: true, stdio: ['ignore', 'pipe', 'pipe'] });
      const timer = setTimeout(() => reject(new Error('Server startup timed out: ' + hostLog)), 20000);
      host.stderr.on('data', chunk => { hostLog += chunk; });
      host.stdout.on('data', chunk => {
        hostLog += chunk;
        const match = hostLog.match(/server listening on (http:\/\/[^\s]+)/);
        if (match) { clearTimeout(timer); resolve(match[1]); }
      });
      host.on('error', reject);
      host.on('exit', code => { clearTimeout(timer); reject(new Error('Server exited: ' + code + '\n' + hostLog)); });
    });
    const result = await new Promise((resolve, reject) => {
      const child = spawn('opencode', ['run', '--server', serverURL, '--format', 'json', '--title', 'Fixture', 'Run fixture_mark once then finish.'], { cwd: directory, env, detached: true, stdio: ['ignore', 'pipe', 'pipe'] });
      let output = '';
      child.stdout.on('data', chunk => { output += chunk; });
      child.stderr.on('data', chunk => { output += chunk; });
      const timer = setTimeout(() => { if (child.pid) process.kill(-child.pid, 'SIGKILL'); }, 45000);
      child.on('error', reject);
      child.on('close', code => { clearTimeout(timer); resolve({ code, output }); });
    });
    if (exhausted) {
      assert.notEqual(result.code, null, 'Exhaustion must stop before the watchdog');
      assert.doesNotMatch(result.output, /FALLBACK_OK/);
      assert.match(result.output, /quota exceeded/);
      assert.deepEqual(requests.map(r => r.model), ['primary', 'primary', 'backup', 'backup-2', 'backup-3', 'backup-4']);
    } else {
      assert.equal(result.code, 0, result.output + hostLog);
      assert.match(result.output, /FALLBACK_OK/, hostLog);
      assert.deepEqual(requests.map(r => r.model), ['primary', 'primary', 'backup']);
    }
    const { readFile } = await import('node:fs/promises');
    assert.equal(await readFile(marker, 'utf8'), 'once\n');
    const backup = requests.at(-1);
    assert.equal(backup.messages.filter(m => m.role === 'tool').length, 1);
    assert.match(JSON.stringify(backup.messages), /MARKED_ONCE/);
    console.log(`PASS: native ${status} ${exhausted ? 'chain exhaustion stops after four switches' : 'fallback crosses providers'}; tool context preserved and tool executed once.`);
  } finally {
    if (host?.pid) { try { process.kill(-host.pid, 'SIGKILL'); } catch {} }
    server.closeAllConnections();
    await new Promise(resolve => server.close(resolve));
    await rm(root, { recursive: true, force: true });
  }

}

await check(429);
await check(404);
await check(429, true);
