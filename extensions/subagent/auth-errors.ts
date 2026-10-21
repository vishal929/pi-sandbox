/**
 * Auth-error detection for subagent results.
 *
 * Distinguishes provider credential failures (401/invalid key/quota)
 * from proxy 403s (squid allowlist) and regular task failures.
 */

const AUTH_PATTERNS: RegExp[] = [
  /invalid.*api.?key/i,
  /api.?key.*invalid/i,
  /incorrect api key/i,
  /unauthorized/i,
  /\b401\b/,
  /authentication.*fail/i,
  /failed.*auth/i,
  /expired.*(key|token|credential)/i,
  /token.*expired/i,
  /missing.*(api.?key|credential)/i,
  /no.*auth.*config/i,
  /login required/i,
  /quota.*exceeded/i,
  /insufficient.*quota/i,
  /credit.*exhausted/i,
  /billing/i,
  /overloaded.*credential/i,
  /forbidden.*(key|credential)/i,
  /no API key/i,
];

const PROXY_PATTERNS: RegExp[] = [
  /pi-proxy/i,
  /squid/i,
  /allowlist/i,
  /pi-add-domain/i,
];

export function isProxyError(text: string): boolean {
  return PROXY_PATTERNS.some((re) => re.test(text));
}

export function isAuthErrorText(text: string | undefined | null): boolean {
  if (!text) return false;
  if (isProxyError(text)) return false; // proxy 403 is NOT an auth error
  return AUTH_PATTERNS.some((re) => re.test(text));
}

export type AuthKind = "missing" | "expired" | "quota" | "unknown";

export function classifyAuthError(text: string): AuthKind {
  if (/quota|credit|billing|insufficient/i.test(text)) return "quota";
  if (/expired|unauthorized|\b401\b/i.test(text)) return "expired";
  if (/missing|no .*auth|not found|login required|no API key/i.test(text)) return "missing";
  return "unknown";
}

/**
 * Human-actionable remediation appended to a failed subagent result.
 * Keep it short — it goes back to the main model AND the user.
 */
export function formatAuthRemediation(agent: string, model: string | undefined, detail: string): string {
  const kind = classifyAuthError(detail);
  const modelStr = model ?? "(unknown model)";
  const lines = [
    `Subagent '${agent}' failed on model ${modelStr} with a likely credential problem (${kind}).`,
    `Detail: ${detail.slice(0, 400)}`,
    ``,
    `To fix:`,
    `1. pi auth print-api-key --provider ${modelStr.split("/")[0] ?? "?"} (check key resolves inside container)`,
    `2. If using credentials.env: update credentials/credentials.env on host, then restart agent (env_file only loads on 'up').`,
    `3. If using /login: run /login for that provider (persists to pi-volume auth.json).`,
    `4. Re-pick model: /subagent-model ${agent} <provider/id>  (see pi --list-models)`,
    `5. Retry the subagent task once. Do NOT silently fall back to an expensive model.`,
  ];
  return lines.join("\n");
}

export function decorateIfAuthError(
  agent: string,
  model: string | undefined,
  output: string,
): string {
  if (isAuthErrorText(output)) {
    return `${output}\n\n---\n${formatAuthRemediation(agent, model, output)}`;
  }
  return output;
}
