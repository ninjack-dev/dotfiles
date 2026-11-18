/**
 * Renders tool call rows more compactly.
 *
 * Press the configured shortcut (default `alt+t`) to cycle three states:
 *
 * - off     - Pi's normal rendering
 * - compact - one line per call, with vertical padding
 * - tight   - one line per call, without vertical padding
 *
 * Configurable in ~/.pi/agent/extra-settings.json:
 *
 *   { "compactTools": { "shortcut": "alt+t" } }
 */
import {
	formatReadLineRange,
	getAgentDir,
	type ExtensionAPI,
	type ExtensionContext,
	type ToolRenderers,
} from "@earendil-works/pi-coding-agent";
import {
	Box,
	Container,
	Text,
	truncateToWidth,
	type Component,
	type KeyId,
} from "@earendil-works/pi-tui";
import { readFileSync } from "node:fs";
import { join } from "node:path";

type Theme = ExtensionContext["ui"]["theme"];

interface CompactToolsSettings {
	shortcut: KeyId;
}

type ToolMode = "off" | "compact" | "tight";

/**
 * Which part of the standard tool box a slot draws. `full` is the whole box,
 * `top`/`bottom` split it between the call and result slots so both still add up
 * to one box, `line` is the box's background on the content lines only, and
 * `none` leaves the content bare.
 */
type Frame = "full" | "top" | "bottom" | "line" | "none";

const SETTINGS_KEY = "compactTools";
const DEFAULT_SETTINGS: CompactToolsSettings = { shortcut: "alt+t" };
const FALLBACK_PREVIEW_LINES = 10;
const COLLAPSED_ARGS_CHARS = 100;

/** Shared across rows, so cycling changes every row on the next repaint. */
let mode: ToolMode = "off";

/** Per-row bookkeeping, kept off the tool's own renderer state keys. */
const ROW_STATE = Symbol("compact-tools-row");

interface RowState {
	/** Whether a result slot exists for this row. */
	hasResult: boolean;
	/** Last component the tool's own call renderer returned, for its in-place reuse. */
	call?: Component;
	/** Last component the tool's own result renderer returned. */
	result?: Component;
}

function rowState(state: unknown): RowState {
	const holder = state as Record<PropertyKey, unknown>;
	let row = holder[ROW_STATE] as RowState | undefined;
	if (!row) {
		row = { hasResult: false };
		holder[ROW_STATE] = row;
	}
	return row;
}

function readSettings(): CompactToolsSettings {
	let raw: unknown;
	try {
		const path = join(getAgentDir(), "extra-settings.json");
		const parsed = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
		raw = parsed[SETTINGS_KEY];
	} catch {
		raw = undefined;
	}

	const settings: CompactToolsSettings = { ...DEFAULT_SETTINGS };
	if (raw !== null && typeof raw === "object") {
		const shortcut = (raw as Record<string, unknown>).shortcut;
		if (typeof shortcut === "string" && shortcut.trim().length > 0) {
			settings.shortcut = shortcut.trim() as KeyId;
		}
	}
	return settings;
}

function nextMode(current: ToolMode): ToolMode {
	return current === "off" ? "compact" : current === "compact" ? "tight" : "off";
}

/**
 * The shell tools keep a one-second repaint interval in their renderer state
 * while output streams. Those renderers are not called while a row is compact,
 * so stop the interval here instead of leaving it ticking forever.
 */
function stopStreamingTimer(state: unknown): void {
	const holder = state as { interval?: ReturnType<typeof setInterval> } | undefined;
	if (holder?.interval !== undefined) {
		clearInterval(holder.interval);
		holder.interval = undefined;
	}
}

function background(theme: Theme, context: { isPartial: boolean; isError: boolean }): (text: string) => string {
	const token = context.isPartial ? "toolPendingBg" : context.isError ? "toolErrorBg" : "toolSuccessBg";
	return (text) => theme.bg(token, text);
}

function firstLine(text: string): string {
	return text.split("\n")[0] ?? "";
}

function asString(value: unknown): string | undefined {
	return typeof value === "string" ? value : undefined;
}

/** Short, tool-aware argument summary for the one-line row. */
function compactArgs(toolName: string, args: unknown): string {
	if (!args || typeof args !== "object" || Array.isArray(args)) return "";
	const a = args as Record<string, unknown>;

	switch (toolName) {
		case "bash":
		case "powershell": {
			const command = asString(a.command);
			return command ? firstLine(command) : "";
		}
		case "read": {
			const path = asString(a.path);
			return path ? `${path}${formatReadLineRange(a.offset, a.limit)}` : "";
		}
		case "write":
		case "edit":
			return asString(a.path) ?? asString(a.file_path) ?? "";
		case "grep": {
			const pattern = asString(a.pattern) ?? "";
			const path = asString(a.path) || ".";
			const glob = asString(a.glob);
			return `/${pattern}/ in ${path}${glob ? ` (${glob})` : ""}`;
		}
		case "find": {
			const pattern = asString(a.pattern) ?? "";
			const path = asString(a.path) || ".";
			return `${pattern} in ${path}`;
		}
		case "ls":
			return asString(a.path) || ".";
		default: {
			for (const value of Object.values(a)) {
				if (typeof value === "string" && value.length > 0) {
					return firstLine(value);
				}
			}
			return "";
		}
	}
}

function compactCallText(
	toolName: string,
	args: unknown,
	theme: Theme,
	context: { isError: boolean; isPartial: boolean },
): string {
	const status = context.isError ? "error" : context.isPartial ? "running" : "done";
	const icon = status === "error" ? "✗" : status === "running" ? "⚙" : "✓";
	const color = status === "error" ? "error" : status === "running" ? "dim" : "success";

	let line = theme.fg(color, `${icon} `) + theme.fg("toolTitle", toolName);
	const argsText = compactArgs(toolName, args);
	if (argsText) {
		line += theme.fg("dim", ` ${argsText}`);
	}
	return line;
}

/** Mirrors Pi's generic call fallback for tools without their own renderer. */
function genericCallText(toolName: string, args: unknown, theme: Theme, expanded: boolean): string {
	const header = theme.fg("toolTitle", theme.bold(toolName));
	if (args == null) return header;
	const entries =
		typeof args === "object" && !Array.isArray(args)
			? Object.entries(args)
			: ([["args", args]] as [string, unknown][]);
	if (entries.length === 0) return header;
	if (expanded) {
		const lines = entries.map(([key, value]) => {
			const text = typeof value === "string" ? value : (JSON.stringify(value, null, 2) ?? String(value));
			return `  ${key}: ${text.replace(/\t/g, "   ").replace(/\r/g, "").split("\n").join("\n    ")}`;
		});
		return `${header}\n${theme.fg("muted", lines.join("\n"))}`;
	}
	const pairs = entries.map(([key, value]) => `${key}=${JSON.stringify(value) ?? String(value)}`).join(" ");
	const preview =
		pairs.length > COLLAPSED_ARGS_CHARS ? `${pairs.slice(0, COLLAPSED_ARGS_CHARS - 3)}...` : pairs;
	return `${header} ${theme.fg("muted", preview)}`;
}

/** Mirrors Pi's generic result fallback for tools without their own renderer. */
function genericResultText(
	result: { content: Array<{ type: string; text?: string }> },
	theme: Theme,
	expanded: boolean,
	expandHint: string,
): string | undefined {
	const output = result.content
		.filter((content) => content.type === "text")
		.map((content) => content.text ?? "")
		.join("\n");
	if (!output) return undefined;

	const lines = output.split("\n");
	const displayLines = expanded ? lines : lines.slice(0, FALLBACK_PREVIEW_LINES);
	const remaining = lines.length - displayLines.length;
	let text = displayLines.map((line) => theme.fg("toolOutput", line)).join("\n");
	if (remaining > 0) {
		text += `${theme.fg("muted", `\n... (${remaining} more lines,`)} ${expandHint}${theme.fg("muted", ")")}`;
	}
	return text;
}

/** One full-width line of the tool background, matching the box's padding rows. */
class BackgroundLine implements Component {
	constructor(private readonly bgFn: (text: string) => string) {}

	render(width: number): string[] {
		return [this.bgFn(" ".repeat(Math.max(0, width)))];
	}

	invalidate(): void {}
}

class CompactLine implements Component {
	constructor(private readonly getText: () => string) {}

	render(width: number): string[] {
		return [truncateToWidth(this.getText(), width, "…")];
	}

	invalidate(): void {}
}

class EmptyComponent implements Component {
	render(): string[] {
		return [];
	}

	invalidate(): void {}
}

interface SlotLayout {
	children: Component[];
	frame: Frame;
}

function createFrame(layout: SlotLayout, padX: number, bgFn: (text: string) => string): Component {
	if (layout.frame === "full") {
		const box = new Box(padX, 1, bgFn);
		for (const child of layout.children) box.addChild(child);
		return box;
	}

	if (layout.frame === "line") {
		// Background and horizontal padding only: no blank rows above or below.
		const box = new Box(padX, 0, bgFn);
		for (const child of layout.children) box.addChild(child);
		return box;
	}

	const container = new Container();
	if (layout.frame === "none") {
		for (const child of layout.children) container.addChild(child);
		return container;
	}

	const box = new Box(padX, 0, bgFn);
	for (const child of layout.children) box.addChild(child);
	if (layout.frame === "top") {
		container.addChild(new BackgroundLine(bgFn));
		container.addChild(box);
	} else {
		container.addChild(box);
		container.addChild(new BackgroundLine(bgFn));
	}
	return container;
}

/**
 * One slot of a tool row. The call slot draws the top of the row and, while the
 * tool runs, the whole box; the result slot draws the result and closes the box.
 *
 * Layout is chosen at render time, which is what makes a state change apply to
 * rows that are already on screen.
 */
class ToolRowSlot implements Component {
	private builtKey: string | undefined;
	private built: Component | undefined;

	constructor(
		private readonly row: RowState,
		private readonly build: (mode: ToolMode, hasResult: boolean) => SlotLayout,
		private readonly padX: number,
		private readonly bgFn: (text: string) => string,
	) {}

	render(width: number): string[] {
		const current = mode;
		const hasResult = this.row.hasResult;
		const key = `${current}:${hasResult}`;
		if (this.builtKey !== key || !this.built) {
			this.builtKey = key;
			this.built = createFrame(this.build(current, hasResult), this.padX, this.bgFn);
		}
		return this.built.render(width);
	}

	invalidate(): void {
		this.built?.invalidate?.();
	}
}

/**
 * Wrap a tool's own renderers so the same row can draw Pi's normal output, a
 * compact framed line, or a bare one-line row, decided at render time.
 */
function createToolRenderers(toolName: string, base: ToolRenderers | undefined): ToolRenderers {
	const baseCall = base?.renderCall;
	const baseResult = base?.renderResult;
	// A tool that draws its own shell is already unframed.
	const framed = base?.renderShell !== "self";

	return {
		// Needed for the tight state, which drops the default shell's vertical padding.
		renderShell: "self",

		renderCall(args, theme, context) {
			const row = rowState(context.state);
			const padX = context.outputPad;

			const callContent = (): Component => {
				if (!baseCall) {
					return new Text(genericCallText(toolName, args, theme, context.expanded), 0, 0);
				}
				try {
					const component = baseCall(args, theme, { ...context, lastComponent: row.call });
					row.call = component;
					return component;
				} catch {
					return new Text(genericCallText(toolName, args, theme, context.expanded), 0, 0);
				}
			};

			return new ToolRowSlot(
				row,
				(current, hasResult) => {
					if (current === "off") {
						// The result slot closes the box, so a finished row only needs its top half here.
						return { children: [callContent()], frame: framed ? (hasResult ? "top" : "full") : "none" };
					}
					stopStreamingTimer(context.state);
					return {
						children: [new CompactLine(() => compactCallText(toolName, args, theme, context))],
						frame: current === "compact" ? "full" : "line",
					};
				},
				padX,
				background(theme, context),
			);
		},

		renderResult(result, options, theme, context) {
			const row = rowState(context.state);
			row.hasResult = true;
			const padX = context.outputPad;

			const resultContent = (): Component => {
				const fallback = (): Component => {
					const text = genericResultText(
						result,
						theme,
						options.expanded,
						context.keyHint("app.tools.expand", "to expand"),
					);
					return text === undefined ? new EmptyComponent() : new Text(text, 0, 0);
				};
				if (!baseResult) return fallback();
				try {
					const component = baseResult(result, options, theme, { ...context, lastComponent: row.result });
					row.result = component;
					return component;
				} catch {
					return fallback();
				}
			};

			return new ToolRowSlot(
				row,
				(current) => {
					if (current === "off") {
						return { children: [resultContent()], frame: framed ? "bottom" : "none" };
					}
					stopStreamingTimer(context.state);
					return { children: [new EmptyComponent()], frame: "none" };
				},
				padX,
				background(theme, context),
			);
		},
	};
}

export default function (pi: ExtensionAPI) {
	const settings = readSettings();

	pi.registerToolRenderer((toolName, next) => createToolRenderers(toolName, next()));

	const repaint = (ctx: ExtensionContext): void => {
		// setStatus always requests a render. Passing undefined keeps the footer
		// clean, so this only exists to repaint the transcript in the new state.
		ctx.ui.setStatus("compact-tools", undefined);
	};

	pi.registerShortcut(settings.shortcut, {
		description: "Cycle tool rows: normal, compact, tight",
		handler: (ctx) => {
			mode = nextMode(mode);
			repaint(ctx);
		},
	});

	pi.on("session_start", async (_event, ctx) => {
		// Clear a status left behind by an older version or a reload.
		repaint(ctx);
	});
}
