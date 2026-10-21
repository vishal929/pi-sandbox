# Subagent extension (pi-sandbox fork)

Vendored from Pi's `examples/extensions/subagent` + pi-sandbox wiring:

- **Model choice (req 1):** per-call `model` param > `subagent-models.json` (global `~/.pi/agent/`, project `<cwd>/.pi/` wins) > `agents/*.md` `model:` fallback > parent `ctx.model`. Manage via `/subagent-model [agent] [provider/id]` (menu when no args). No hardcoded model required — `explorer.md`/`implementer.md` ship without `model:`.
- **Permission inheritance (req 2):** child `pi` runs in same container, same RO global `pi-permissions.jsonc` + project `.pi/agent/pi-permissions.jsonc`. Per-agent tightening via `permission:` frontmatter in `agents/*.md` (explorer denies writes/bash, implementer asks). `--tools` allowlist from frontmatter still applied.
- **Forwarding (req 3):** child spawned with `PI_IS_SUBAGENT=1`, `PI_AGENT_ROUTER_PARENT_SESSION_ID=<parent>`, `PI_PERMISSION_SYSTEM_FORWARDING_AGENT_DIR=<agentDir>` so `pi-permission-system` `ask` prompts route to parent UI. Denies/timeouts return as tool errors; chain stops, parallel reports per-task.
- **Auth errors:** preflight via `modelRegistry.find()` + `hasConfiguredAuth()` fails fast before spawn. Runtime `401/invalid key/quota` matched in `auth-errors.ts` and appended with remediation (`pi auth print-api-key`, fix `credentials.env` + restart, `/login`, `/subagent-model`). Proxy 403 (squid allowlist) is explicitly NOT treated as auth — follow `pi-add-domain` flow.

## Files

- `index.ts` — tool + `/subagent-model` command
- `agents.ts` — discovery (user dir)
- `auth-errors.ts` — `isAuthErrorText`, `formatAuthRemediation`, `decorateIfAuthError`
- `model-config.ts` — load/save/resolve mapping
- `agents/explorer.md`, `agents/implementer.md` — role + tools + permission tightening
- `subagent-models.json.example` — copy to agent dir

## Mounts (see `bin/pi-start.sh`)

- `extensions/subagent:/home/node/.pi/agent/extensions/subagent:ro`
- `extensions/subagent/agents:/home/node/.pi/agent/agents:ro`
