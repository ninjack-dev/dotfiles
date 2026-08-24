import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createPowerShellToolDefinition, type BashOperations } from "@earendil-works/pi-coding-agent";

const ARGS = ["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"];

const operations: BashOperations = {
	exec: async (command, cwd, { onData, signal, timeout, env }) => {
		return new Promise((resolve, reject) => {
			const child = spawn("pwsh", [...ARGS, command], { cwd, env, detached: true, stdio: ["ignore", "pipe", "pipe"] });
			child.stdout?.on("data", onData);
			child.stderr?.on("data", onData);
			const kill = () => { try { process.kill(-child.pid!, "SIGKILL"); } catch { child.kill("SIGKILL"); } };
			child.once("error", (err) => { signal?.removeEventListener("abort", kill); reject(err); });
			child.once("close", (code) => { signal?.removeEventListener("abort", kill); resolve({ exitCode: code }); });
			if (timeout !== undefined) setTimeout(kill, timeout);
			if (signal) {
				if (signal.aborted) kill();
				else signal.addEventListener("abort", kill, { once: true });
			}
		});
	},
};

export default function pwshOverride(pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		const def = createPowerShellToolDefinition(ctx.cwd, { operations });
		pi.registerTool({
			name: "powershell",
			label: def.label,
			description: def.description,
			parameters: def.parameters,
			promptSnippet: def.promptSnippet,
			promptGuidelines: def.promptGuidelines,
			execute: def.execute,
		});
	});
}
