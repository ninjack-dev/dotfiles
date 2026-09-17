/**
 * Pi Notify Extension
 *
 * Sends a native terminal notification when the Pi agent turn is done and Pi
 * is waiting for input.
 *
 * By default the extension stays quiet. Press the configured shortcut
 * (default `alt+n`) to toggle a one-shot notification: the next time the agent
 * settles, a native notification fires and the toggle resets.
 *
 * A persistent on/off indicator is rendered in the bottom-right corner of the
 * footer. To place it there, the extension installs its own footer that wraps
 * the built-in FooterComponent, so pwd, token stats, context usage and model
 * info are all preserved.
 *
 * Config lives in ~/.pi/agent/extra-settings.json, under the key `notify`:
 *
 *   {
 *     "notify": {
 *       "shortcut": "alt+n",
 *       "title": "Pi",
 *       "body": "Ready for input",
 *       "icon": "pi-coding-agent",
 *       "indicatorOn": "\uf0f3",
 *       "indicatorOff": "\uf1f6"
 *     }
 *   }
 *
 * `icon` is only used by the Kitty (OSC 99) path. It is an icon name resolved
 * from the XDG icon theme; set it to an empty string to omit the icon.
 *
 * `indicatorOn` / `indicatorOff` accept any string. Set `indicatorOff` to ""
 * to hide the indicator while disarmed.
 *
 * Supported terminal protocols:
 * - OSC 777: Ghostty, iTerm2, WezTerm, rxvt-unicode
 * - OSC 99: Kitty (supports icon names via the `n` metadata key)
 * - Windows toast: Windows Terminal (WSL)
 */

import {
	FooterComponent,
	getAgentDir,
	type ExtensionAPI,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { type KeyId, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { readFileSync } from "node:fs";
import { join } from "node:path";

interface NotifySettings {
	shortcut: KeyId;
	title: string;
	body: string;
	icon: string;
	indicatorOn: string;
	indicatorOff: string;
}

const DEFAULT_SETTINGS: NotifySettings = {
	shortcut: "alt+n",
	title: "Pi",
	body: "Ready for input",
	icon: "pi-coding-agent",
	// Nerd Font glyphs present in JetBrainsMono Nerd Font:
	// nf-fa-bell / nf-fa-bell-slash.
	indicatorOn: "\uf0f3",
	indicatorOff: "\uf1f6",
};

function readSettings(): NotifySettings {
	let raw: unknown;
	try {
		const path = join(getAgentDir(), "extra-settings.json");
		const parsed = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
		raw = parsed["notify"];
	} catch {
		raw = undefined;
	}

	const settings: NotifySettings = { ...DEFAULT_SETTINGS };
	if (raw !== null && typeof raw === "object") {
		const value = raw as Record<string, unknown>;
		if (typeof value.shortcut === "string" && value.shortcut.trim().length > 0) {
			settings.shortcut = value.shortcut.trim() as KeyId;
		}
		if (typeof value.title === "string" && value.title.length > 0) {
			settings.title = value.title;
		}
		if (typeof value.body === "string" && value.body.length > 0) {
			settings.body = value.body;
		}
		if (typeof value.icon === "string") {
			settings.icon = value.icon.trim();
		}
		if (typeof value.indicatorOn === "string") {
			settings.indicatorOn = value.indicatorOn;
		}
		if (typeof value.indicatorOff === "string") {
			settings.indicatorOff = value.indicatorOff;
		}
	}
	return settings;
}

function windowsToastScript(title: string, body: string): string {
	const type = "Windows.UI.Notifications";
	const mgr = `[${type}.ToastNotificationManager, ${type}, ContentType = WindowsRuntime]`;
	const template = `[${type}.ToastTemplateType]::ToastText01`;
	const toast = `[${type}.ToastNotification]::new($xml)`;
	return [
		`${mgr} > $null`,
		`$xml = [${type}.ToastNotificationManager]::GetTemplateContent(${template})`,
		`$xml.GetElementsByTagName('text')[0].AppendChild($xml.CreateTextNode('${body}')) > $null`,
		`[${type}.ToastNotificationManager]::CreateToastNotifier('${title}').Show(${toast})`,
	].join("; ");
}

function notifyOSC777(title: string, body: string): void {
	process.stdout.write(`\x1b]777;notify;${title};${body}\x07`);
}

function base64(text: string): string {
	return Buffer.from(text, "utf8").toString("base64");
}

function notifyOSC99(title: string, body: string, icon: string): void {
	// Kitty OSC 99: i=notification id, d=0 means not done yet, p=body for the
	// second part. `n` is a base64-encoded icon name resolved from the XDG icon
	// theme; `f` is the base64-encoded application name and also acts as an
	// icon fallback. The `n` key may repeat; kitty uses the first icon it finds.
	const metadata = ["i=1", "d=0", `f=${base64("pi-coding-agent")}`];
	if (icon.length > 0) {
		metadata.push(`n=${base64(icon)}`);
	}
	process.stdout.write(`\x1b]99;${metadata.join(":")};${title}\x1b\\`);
	process.stdout.write(`\x1b]99;i=1:p=body;${body}\x1b\\`);
}

function notifyWindows(title: string, body: string): void {
	const { execFile } = require("child_process");
	execFile("powershell.exe", ["-NoProfile", "-Command", windowsToastScript(title, body)]);
}

function notify(title: string, body: string, icon: string): void {
	if (process.env.WT_SESSION) {
		notifyWindows(title, body);
	} else if (process.env.KITTY_WINDOW_ID) {
		notifyOSC99(title, body, icon);
	} else {
		notifyOSC777(title, body);
	}
}

/**
 * `FooterComponent` calls `session.modelRuntime.isUsingSubscription()`, but the
 * extension context only exposes a ModelRegistry. Try the underlying runtime
 * first, then fall back to OAuth detection, then to false.
 */
function isUsingSubscription(ctx: ExtensionContext, providerId: string): boolean {
	if (providerId === "kimi-coding") return true;
	const runtime = (
		ctx.modelRegistry as unknown as { runtime?: { isUsingSubscription?: (id: string) => boolean } }
	).runtime;
	if (typeof runtime?.isUsingSubscription === "function") {
		return runtime.isUsingSubscription(providerId);
	}
	const model = ctx.model;
	return model ? ctx.modelRegistry.isUsingOAuth(model) : false;
}

export default function (pi: ExtensionAPI) {
	const settings = readSettings();
	let armed = false;
	let refreshFooter: (() => void) | undefined;

	const installFooter = (ctx: ExtensionContext): void => {
		if (!ctx.hasUI) return;

		// Minimal AgentSession stand-in for the built-in FooterComponent. It only
		// reads state (model/thinking), sessionManager, getContextUsage(), and
		// modelRuntime.isUsingSubscription(); everything else is self-contained.
		const sessionLike = {
			get state() {
				return { model: ctx.model, thinkingLevel: ctx.thinkingLevel };
			},
			sessionManager: ctx.sessionManager,
			getContextUsage: () => ctx.getContextUsage(),
			modelRuntime: {
				isUsingSubscription: (providerId: string) => isUsingSubscription(ctx, providerId),
			},
		};

		ctx.ui.setFooter((tui, theme, footerData) => {
			const base = new FooterComponent(
				sessionLike as unknown as ConstructorParameters<typeof FooterComponent>[0],
				footerData,
			);
			const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
			refreshFooter = () => tui.requestRender();

			return {
				dispose() {
					unsubscribe();
					base.dispose();
					refreshFooter = undefined;
				},
				invalidate() {
					base.invalidate();
				},
				render(width: number): string[] {
					const glyph = armed ? settings.indicatorOn : settings.indicatorOff;
					if (glyph.length === 0) {
						return base.render(width);
					}
					const colored = theme.fg(armed ? "accent" : "dim", glyph);
					const glyphWidth = visibleWidth(glyph);
					// Render the built-in footer narrower so the indicator never
					// overlaps the model name, then right-align the indicator on the
					// last line.
					const lines = base.render(Math.max(1, width));
					if (lines.length === 0) {
						return [truncateToWidth(colored, width)];
					}
					const lastIndex = lines.length - 1;
					const last = lines[lastIndex] ?? "";
					const pad = Math.max(1, width - visibleWidth(last) - glyphWidth);
					lines[lastIndex] = truncateToWidth(last + " ".repeat(pad) + colored, width);
					return lines;
				},
			};
		});
	};

	pi.on("session_start", async (_event, ctx) => {
		installFooter(ctx);
	});

	pi.on("session_shutdown", async () => {
		refreshFooter = undefined;
	});

	pi.registerShortcut(settings.shortcut, {
		description: "Toggle notify when the next agent turn completes",
		handler: (ctx) => {
			armed = !armed;
			refreshFooter?.();
			ctx.ui.notify(
				armed ? "Armed: will notify when the next turn completes." : "Disarmed: no notification.",
				"info",
			);
		},
	});

	// `agent_end` fires after each low-level run; Pi may still retry, compact,
	// or continue with queued follow-ups. Notify only after the full run settles.
	pi.on("agent_settled", async () => {
		if (!armed) return;
		armed = false;
		refreshFooter?.();
		notify(settings.title, settings.body, settings.icon);
	});
}
