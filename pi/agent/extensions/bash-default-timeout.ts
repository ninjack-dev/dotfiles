/**
 * Default bash timeout.
 *
 * Applies a default timeout (in seconds) to agent bash tool calls when the
 * agent did not specify one itself, guarding against runaway commands.
 *
 * Config lives in ~/.pi/agent/extra-settings.json,
 * under the key `bashDefaultTimeout`:
 *
 *   { "bashDefaultTimeoutS": 10 }
 *
 */
import { getAgentDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const SETTINGS_KEY = "bashDefaultTimeout";
const FALLBACK_TIMEOUT = 10;

function readDefaultTimeout(): number {
	let raw: unknown;
	try {
		const path = join(getAgentDir(), "extra-settings.json");
		const parsed = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
		raw = parsed[SETTINGS_KEY];
	} catch {
		raw = undefined;
	}

	const value = typeof raw === "number" ? raw : FALLBACK_TIMEOUT;
	return Number.isFinite(value) && value > 0 ? value : FALLBACK_TIMEOUT;
}

export default function (pi: ExtensionAPI) {
	const defaultTimeout = readDefaultTimeout();

	pi.on("tool_call", (event) => {
		if (event.toolName !== "bash") return;
		if (event.input.timeout === undefined) {
			event.input.timeout = defaultTimeout;
		}
	});
}
