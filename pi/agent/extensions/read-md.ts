/**
 * Markdown-aware read tool.
 *
 * Overrides the built-in `read` tool so markdown files get structured access
 * instead of a raw dump:
 *
 *   - Short files (maxLines or fewer lines) are returned whole, like read.
 *   - Larger files return the header text (everything before the first H1/H2)
 *     followed by a table of contents. Every heading gets a dotted outline
 *     section ID (1.2.3 style), so duplicate headings are resolved by
 *     position rather than by text.
 *   - read(path, section="1.2.3") returns that section's content verbatim.
 *     An exact heading title also works; duplicate titles are reported with
 *     their candidate IDs.
 *   - read(path, search="term") returns truncated matches grouped by the
 *     section they appear in, so the agent can pick the right section to
 *     read in full.
 *   - offset/limit keep their built-in raw-window semantics for any file
 *     type. Non-markdown files delegate to the built-in read implementation
 *     unchanged, including image handling and truncation notices.
 *
 * Config lives in agent/extra-settings.json under the "read-md" key:
 *
 *   {
 *     "read-md": {
 *       "maxLines": 50,
 *       "searchLimit": 20,
 *       "snippetChars": 100,
 *       "snippetsPerSection": 3
 *     }
 *   }
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import {
	createReadToolDefinition,
	DEFAULT_MAX_BYTES,
	DEFAULT_MAX_LINES,
	formatSize,
	getAgentDir,
	truncateHead,
} from "@earendil-works/pi-coding-agent";
import { readFileSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { join, resolve as resolvePath } from "node:path";
import { marked } from "marked";
import { Type, type Static } from "typebox";

const TOOL_NAME = "read";
const MARKDOWN_EXTENSION = /\.(md|markdown|mdx)$/i;

interface ReadMdSettings {
	maxLines: number;
	searchLimit: number;
	snippetChars: number;
	snippetsPerSection: number;
}

const DEFAULT_SETTINGS: ReadMdSettings = {
	maxLines: 50,
	searchLimit: 20,
	snippetChars: 100,
	snippetsPerSection: 3,
};

interface HeadingNode {
	id: string;
	depth: number;
	text: string;
	startLine: number;
	endLine: number;
}

const schema = Type.Object({
	path: Type.String({ description: "Path to the file to read (relative or absolute)" }),
	offset: Type.Optional(Type.Number({ description: "Line number to start reading from (1-indexed)" })),
	limit: Type.Optional(Type.Number({ description: "Maximum number of lines to read" })),
	section: Type.Optional(
		Type.String({
			description:
				'Markdown only: dotted section ID from the table of contents (e.g. "1.2.3"), or an exact heading title. Returns that section verbatim.',
		}),
	),
	search: Type.Optional(
		Type.String({
			description:
				"Markdown only: case-insensitive search term. Returns truncated matches grouped by section so the matching section can then be read in full.",
		}),
	),
});

type ReadParams = Static<typeof schema>;

function readSettings(): ReadMdSettings {
	let raw: unknown;
	try {
		const path = join(getAgentDir(), "extra-settings.json");
		const parsed = JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
		raw = parsed["read-md"];
	} catch {
		raw = undefined;
	}
	const settings: ReadMdSettings = { ...DEFAULT_SETTINGS };
	if (raw !== null && typeof raw === "object") {
		const value = raw as Record<string, unknown>;
		settings.maxLines = positiveInt(value.maxLines, settings.maxLines);
		settings.searchLimit = positiveInt(value.searchLimit, settings.searchLimit);
		settings.snippetChars = positiveInt(value.snippetChars, settings.snippetChars);
		settings.snippetsPerSection = positiveInt(value.snippetsPerSection, settings.snippetsPerSection);
	}
	return settings;
}

function positiveInt(value: unknown, fallback: number): number {
	return typeof value === "number" && Number.isFinite(value) && value > 0 ? Math.floor(value) : fallback;
}

function countNewlines(text: string): number {
	let count = 0;
	for (let i = 0; i < text.length; i++) {
		if (text.charCodeAt(i) === 10) count++;
	}
	return count;
}

interface LexedToken {
	type: string;
	raw?: string;
	depth?: number;
	text?: string;
}

/**
 * Walk marked's token list to find every heading and assign dotted outline
 * IDs. Token raws are contiguous in document order, so the line number of a
 * token is the count of newlines in the preceding raws plus one. A heading's
 * subtree ends where the next heading of equal-or-shallower depth starts.
 */
function parseHeadings(text: string, totalLines: number): HeadingNode[] {
	const headings: HeadingNode[] = [];
	let cursor = 0;
	const counters: number[] = [];
	try {
		const tokens = marked.lexer(text) as unknown as LexedToken[];
		for (const token of tokens) {
			const startLine = cursor + 1;
			if (token.type === "heading") {
				const depth = token.depth ?? 1;
				while (counters.length < depth) counters.push(0);
				counters[depth - 1] = (counters[depth - 1] ?? 0) + 1;
				counters.length = depth;
				headings.push({
					id: counters.join("."),
					depth,
					text: (token.text ?? "").trim(),
					startLine,
					endLine: totalLines + 1,
				});
			}
			cursor += countNewlines(token.raw ?? "");
		}
	} catch {
		return [];
	}
	for (let i = 0; i < headings.length; i++) {
		for (let j = i + 1; j < headings.length; j++) {
			if (headings[j].depth <= headings[i].depth) {
				headings[i].endLine = headings[j].startLine;
				break;
			}
		}
	}
	return headings;
}

function resolveHeading(headings: HeadingNode[], selector: string): { heading?: HeadingNode; ambiguous: string[] } {
	const exact = headings.find((h) => h.id === selector);
	if (exact) return { heading: exact, ambiguous: [] };
	const needle = selector.trim().toLowerCase();
	const matches = headings.filter((h) => h.text.toLowerCase() === needle);
	if (matches.length === 1) return { heading: matches[0], ambiguous: [] };
	return { ambiguous: matches.map((m) => m.id) };
}

function formatLineRange(startLine: number, endLine: number): string {
	if (endLine <= startLine) return `line ${startLine}`;
	return `lines ${startLine}-${endLine}`;
}

function renderOverview(filePath: string, text: string, lines: string[], headings: HeadingNode[], maxLines: number): string {
	const totalLines = lines.length;
	// No headings means the whole file is header text, so return it as-is.
	if (headings.length === 0 || totalLines <= maxLines) return text;
	const firstH12 = headings.find((h) => h.depth <= 2);
	const preambleEnd = firstH12 ? firstH12.startLine - 1 : totalLines;
	const out: string[] = [`File: ${filePath} (${totalLines} lines)`];
	if (preambleEnd > 0) {
		out.push("", `== Header (lines 1-${preambleEnd}) ==`, lines.slice(0, preambleEnd).join("\n"));
	}
	out.push("", "== Table of Contents ==");
	out.push(`Read a section: read(path="${filePath}", section="1.2")`);
	out.push(`Search this document: read(path="${filePath}", search="term")`);
	out.push("");
	for (const h of headings) {
		const endLine = Math.min(h.endLine - 1, totalLines);
		const size = endLine - h.startLine + 1;
		const indent = "  ".repeat(h.depth - 1);
		const sizeNote = size > 1 ? ` (${size} lines)` : "";
		out.push(`${indent}[${h.id}]`.padEnd(10 + indent.length) + `${h.text} ${formatLineRange(h.startLine, endLine)}${sizeNote}`);
	}
	return out.join("\n");
}

function renderSection(filePath: string, lines: string[], headings: HeadingNode[], selector: string): { text: string; ok: boolean } {
	const { heading, ambiguous } = resolveHeading(headings, selector);
	if (!heading) {
		const hint = ambiguous.length > 0 ? `matches ${ambiguous.join(", ")}` : "not found";
		return {
			text: `Section "${selector}" ${hint}. Use a dotted section ID from the table of contents (e.g. "1.2.3") or an exact heading title.`,
			ok: false,
		};
	}
	const totalLines = lines.length;
	const startIdx = heading.startLine - 1;
	const endIdx = Math.min(heading.endLine - 1, totalLines);
	const body = lines.slice(startIdx, endIdx).join("\n").replace(/\n+$/, "");
	const size = endIdx - startIdx;
	const banner = `# Section ${heading.id} "${heading.text}" (${formatLineRange(heading.startLine, endIdx)}, ${size} line${size === 1 ? "" : "s"})`;
	const truncation = truncateHead(body);
	let out = `${banner}\n${truncation.content}`;
	if (truncation.firstLineExceedsLimit) {
		out += `\n[Line ${heading.startLine} alone exceeds ${formatSize(DEFAULT_MAX_BYTES)}. Use read(path="${filePath}", offset=${heading.startLine}) or bash.]`;
	} else if (truncation.truncated) {
		const nextOffset = heading.startLine + truncation.outputLines;
		out += `\n[Section truncated (${formatSize(DEFAULT_MAX_BYTES)} / ${DEFAULT_MAX_LINES} lines limit). Continue with read(path="${filePath}", offset=${nextOffset}) or read a subsection ID.]`;
	}
	return { text: out, ok: true };
}

function snippetFor(line: string, index: number, queryLength: number, chars: number): string {
	const half = Math.floor((chars - queryLength) / 2);
	let start = Math.max(0, index - half);
	let end = Math.min(line.length, index + queryLength + half);
	// Expand to word boundaries so words are not cut mid-way (bounded).
	let guard = 0;
	while (start > 0 && !/\s/.test(line[start - 1]) && guard < 20) {
		start -= 1;
		guard += 1;
	}
	guard = 0;
	while (end < line.length && !/\s/.test(line[end]) && guard < 20) {
		end += 1;
		guard += 1;
	}
	const cut = line.slice(start, end).trim();
	return `${start > 0 ? "..." : ""}${cut}${end < line.length ? "..." : ""}`;
}

function owningHeading(headings: HeadingNode[], lineNo: number): HeadingNode | undefined {
	let best: HeadingNode | undefined;
	for (const h of headings) {
		if (h.startLine <= lineNo && lineNo < h.endLine && (best === undefined || h.depth > best.depth)) {
			best = h;
		}
	}
	return best;
}

function escapeXml(value: string): string {
	return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

function renderSearch(
	filePath: string,
	lines: string[],
	headings: HeadingNode[],
	query: string,
	settings: ReadMdSettings,
	scope?: { start: number; end: number; headingId: string },
): string {
	const needle = query.toLowerCase();
	const buckets: Array<{ heading: HeadingNode; matches: number; snippets: string[] }> = [];
	const overflowSections = new Set<HeadingNode>();
	let totalMatches = 0;
	let overflowMatches = 0;
	const start = scope?.start ?? 0;
	const end = scope?.end ?? lines.length;
	for (let i = start; i < end; i++) {
		const lower = lines[i].toLowerCase();
		let count = 0;
		let first = -1;
		let from = 0;
		for (;;) {
			const at = lower.indexOf(needle, from);
			if (at === -1) break;
			if (first === -1) first = at;
			count += 1;
			from = at + needle.length;
		}
		if (count === 0) continue;
		const lineNo = i + 1;
		totalMatches += count;
		const owner = owningHeading(headings, lineNo);
		// Matches in the preamble are skipped; the overview already shows it in full.
		if (!owner) continue;
		let bucket = buckets.find((b) => b.heading === owner);
		if (!bucket) {
			if (buckets.length >= settings.searchLimit) {
				overflowMatches += count;
				overflowSections.add(owner);
				continue;
			}
			bucket = { heading: owner, matches: 0, snippets: [] };
			buckets.push(bucket);
		}
		bucket.matches += count;
		if (first !== -1 && bucket.snippets.length < settings.snippetsPerSection) {
			bucket.snippets.push(`(line ${lineNo}) ${snippetFor(lines[i], first, needle.length, settings.snippetChars)}`);
		}
	}
	const out: string[] = [];
	const scopeAttr = scope ? ` section="${escapeXml(scope.headingId ?? "")}"` : "";
	out.push(
		`<search-results file="${escapeXml(filePath)}" query="${escapeXml(query)}" sections="${buckets.length}" matches="${totalMatches}"${scopeAttr}>`,
	);
	for (const bucket of buckets) {
		const h = bucket.heading;
		out.push(`<result section="${escapeXml(h.id)}" title="${escapeXml(h.text)}" matches="${bucket.matches}">`);
		for (const snippet of bucket.snippets) out.push(snippet);
		if (bucket.snippets.length < bucket.matches) {
			out.push(`(first ${bucket.snippets.length} of ${bucket.matches} matches shown)`);
		}
		out.push("</result>");
	}
	if (overflowSections.size > 0) {
		out.push(
			`<note>${overflowMatches} more matches in ${overflowSections.size} additional sections not shown (search limit ${settings.searchLimit}).</note>`,
		);
	} else if (buckets.length === 0) {
		out.push(`<note>No matches for "${escapeXml(query)}".</note>`);
	}
	out.push("</search-results>");
	return out.join("\n");
}

export default function (pi: ExtensionAPI) {
	const settings = readSettings();
	// Instance only used to copy prompt/renderer fields onto the override.
	const builtin = createReadToolDefinition(".");
	const builtinByCwd = new Map<string, ReturnType<typeof createReadToolDefinition>>();
	const getBuiltin = (cwd: string) => {
		let def = builtinByCwd.get(cwd);
		if (!def) {
			def = createReadToolDefinition(cwd);
			builtinByCwd.set(cwd, def);
		}
		return def;
	};

	async function readMarkdown(path: string, ctx: ExtensionContext): Promise<{ text: string; lines: string[] }> {
		const absolutePath = resolvePath(ctx.cwd, path);
		let text: string;
		try {
			text = await readFile(absolutePath, "utf8");
		} catch (error) {
			throw new Error(`Cannot read ${path}: ${(error as Error).message}`);
		}
		return { text, lines: text.split("\n") };
	}

	pi.registerTool({
		name: TOOL_NAME,
		label: TOOL_NAME,
		description: [
			"Read the contents of a file. Supports text files and images (jpg, png, gif, webp, bmp); images are sent as attachments. For text files, output is truncated to 2000 lines or 50KB (whichever is hit first). Use offset/limit for large files.",
			'Markdown files (.md, .markdown, .mdx) additionally get structured access: without offset/limit, files of at most maxLines lines are returned whole, while larger files return the header text and a table of contents with dotted section IDs (e.g. "1.2.3"). Pass section="1.2.3" to read that section verbatim, or search="term" to get truncated matches grouped by section.',
		].join("\n"),
		promptSnippet: builtin.promptSnippet,
		promptGuidelines: builtin.promptGuidelines,
		parameters: schema,
		// Preserve the built-in read TUI rendering for delegated non-markdown reads.
		renderCall: builtin.renderCall as unknown as never,
		renderResult: builtin.renderResult as unknown as never,
		async execute(toolCallId, params: ReadParams, signal, onUpdate, ctx) {
			if (signal?.aborted) throw new Error("Operation aborted");
			const isMarkdown = MARKDOWN_EXTENSION.test(params.path);
			if (!isMarkdown) {
				if (params.section !== undefined || params.search !== undefined) {
					return {
						content: [
							{
								type: "text",
								text: `Not a markdown file: ${params.path}. The section/search options only apply to markdown files; use offset/limit for raw windows.`,
							},
						],
						details: {},
					};
				}
				return getBuiltin(ctx.cwd).execute(
					toolCallId,
					{ path: params.path, offset: params.offset, limit: params.limit },
					signal,
					onUpdate,
					ctx,
				);
			}

			const file = await readMarkdown(params.path, ctx);
			const headings = parseHeadings(file.text, file.lines.length);

			if (params.search !== undefined) {
				let scope: { start: number; end: number; headingId: string } | undefined;
				if (params.section !== undefined) {
					const { heading } = resolveHeading(headings, params.section);
					if (heading) {
						scope = {
							start: heading.startLine - 1,
							end: Math.min(heading.endLine - 1, file.lines.length),
							headingId: heading.id,
						};
					}
				}
				return {
					content: [{ type: "text", text: renderSearch(params.path, file.lines, headings, params.search, settings, scope) }],
					details: { mode: "search", section: scope?.headingId },
				};
			}
			if (params.section !== undefined) {
				const result = renderSection(params.path, file.lines, headings, params.section);
				return {
					content: [{ type: "text", text: result.text }],
					details: { mode: "section", ok: result.ok },
				};
			}
			if (params.offset !== undefined || params.limit !== undefined) {
				return getBuiltin(ctx.cwd).execute(
					toolCallId,
					{ path: params.path, offset: params.offset, limit: params.limit },
					signal,
					onUpdate,
					ctx,
				);
			}
			return {
				content: [{ type: "text", text: renderOverview(params.path, file.text, file.lines, headings, settings.maxLines) }],
				details: { mode: "overview" },
			};
		},
	});
}