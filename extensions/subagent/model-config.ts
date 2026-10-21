/**
 * Model resolution for subagents.
 *
 * Precedence (highest first):
 *   1. per-call `model` param on the subagent tool (single/tasks/chain item)
 *   2. subagent-models.json mapping (project overrides global)
 *   3. `model:` frontmatter in agents/<name>.md (fallback default)
 *   4. parent dispatch default (ctx.model provider/id)
 *
 * Config files:
 *   - global:  ~/.pi/agent/subagent-models.json  (getAgentDir())
 *   - project: <cwd>/.pi/subagent-models.json
 * Shape: { "<agentName>": "provider/model-id", ... }
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { CONFIG_DIR_NAME, getAgentDir } from "@earendil-works/pi-coding-agent";

export type SubagentModelMap = Record<string, string>;

export function loadSubagentModelMap(cwd: string): { map: SubagentModelMap; globalPath: string; projectPath: string } {
  const globalPath = path.join(getAgentDir(), "subagent-models.json");
  const projectPath = path.join(cwd, CONFIG_DIR_NAME, "subagent-models.json");
  let globalMap: SubagentModelMap = {};
  let projectMap: SubagentModelMap = {};
  try {
    if (fs.existsSync(globalPath)) globalMap = JSON.parse(fs.readFileSync(globalPath, "utf-8"));
  } catch {
    /* ignore parse errors — treat as empty */
  }
  try {
    if (fs.existsSync(projectPath)) projectMap = JSON.parse(fs.readFileSync(projectPath, "utf-8"));
  } catch {
    /* ignore */
  }
  return { map: { ...globalMap, ...projectMap }, globalPath, projectPath };
}

export function saveSubagentModel(agent: string, model: string): { path: string } {
  const globalPath = path.join(getAgentDir(), "subagent-models.json");
  let cur: SubagentModelMap = {};
  try {
    if (fs.existsSync(globalPath)) cur = JSON.parse(fs.readFileSync(globalPath, "utf-8"));
  } catch {
    cur = {};
  }
  cur[agent] = model;
  fs.mkdirSync(path.dirname(globalPath), { recursive: true });
  fs.writeFileSync(globalPath, JSON.stringify(cur, null, 2) + "\n", "utf-8");
  return { path: globalPath };
}

export function parseModelString(model: string): { provider: string; id: string } | null {
  const slash = model.indexOf("/");
  if (slash <= 0 || slash === model.length - 1) return null;
  return { provider: model.slice(0, slash), id: model.slice(slash + 1).split(":")[0] };
}

export function resolveSubagentModel(opts: {
  override?: string;
  mapping?: SubagentModelMap;
  agentName: string;
  agentMdModel?: string;
  dispatchDefault?: string;
}): string | undefined {
  if (opts.override?.trim()) return opts.override.trim();
  const mapped = opts.mapping?.[opts.agentName];
  if (mapped?.trim()) return mapped.trim();
  if (opts.agentMdModel?.trim()) return opts.agentMdModel.trim();
  return opts.dispatchDefault;
}
