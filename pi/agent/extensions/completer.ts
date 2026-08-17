/**
 * completer.ts — Replacement for the built-in `@` completer: files listed in
 * `.git/info/exclude` become completable, `.gitignore`'d files stay out.
 *
 * Pi's built-in `@` fuzzy completion shells out to `fd`, which by default
 * respects every git ignore source at once: `.gitignore`, `.git/info/exclude`,
 * and the global core.excludesFile. There is no fd flag that separates them,
 * and pi exposes no setting for this. ripgrep, however, has the exact flag we
 * need: `--no-ignore-exclude` disables only the manually-configured excludes
 * (git's `.git/info/exclude`) while `.gitignore` rules stay in effect — the
 * desired completion set in a single pass.
 *
 * Candidate sources (preference order; resolved once per session, like the
 * built-in provider resolves its fd path):
 *
 *   rg    ripgrep --files --no-ignore-exclude   -> exact semantics in one pass
 *   fd    three passes, set-union                -> same semantics via A ∪ (B ∖ C)
 *   node  readdir walk, honours no ignore rules  -> last resort, shows everything
 *
 * The fd fallback passes:
 *   A: fd (default)                          -> "clean" set (gitignore + exclude respected)
 *   B: fd --no-ignore-vcs                    -> everything (gitignore + exclude ignored)
 *   C: fd --no-ignore-vcs --ignore-file .git/info/exclude -> everything except info/exclude
 *   extras = B ∖ C                           -> files ignored by info/exclude only
 *   result = A ∪ extras
 *
 * PROVENANCE — BORROWED CODE, VERIFIED AGAINST UPSTREAM:
 *   The reference is the upstream TypeScript source, NOT the transpiled
 *   dist/autocomplete.js:
 *
 *     repo: earendil-works/pi-mono
 *     file: packages/tui/src/autocomplete.ts
 *     tag:  v0.84.2
 *     last verified: 2026-08-16
 *
 *   (The .ts text bundled into pi 0.84.2's dist source map is identical to the
 *   tag — `diff` was clean.) If you update pi, re-check these functions
 *   against the newer tag before trusting this extension.
 *
 *   - Verbatim (code text identical to upstream; upstream's decorative
 *     function-label comment lines are removed here):
 *       toDisplayPath, escapeRegex, buildFdPathQuery, findLastDelimiter,
 *       findUnclosedQuoteStart, isTokenStart, extractQuotedPrefix,
 *       parsePathPrefix, buildCompletionValue.
 *   - Verbatim except documented splices: walkDirectoryWithFd keeps upstream's
 *       arg construction and line parsing, gains a final
 *       `extraArgs: string[] = []` parameter (one `...extraArgs,` line in the
 *       args array; with no extra args the emitted fd command is identical),
 *       and delegates spawn plumbing to the shared collectProcessOutput()
 *       helper (extension-owned, extracted from the upstream function's
 *       inline code).
 *   - Mechanical ports (class methods; the ONLY edits are `private` removed
 *       and, where noted, `this.x` → named parameter):
 *       extractAtPrefix, expandHomePath, scopedPathForDisplay, scoreEntry:
 *           `private` keyword removed, nothing else.
 *       resolveScopedFuzzyQuery(rawQuery, basePath):
 *           `private` removed; this.basePath → basePath;
 *           this.expandHomePath → expandHomePath.
 *       rankAndFormatFuzzyEntries(...): the scoring/sorting/formatting tail of
 *           getFuzzyFileSuggestions; this.scoreEntry → scoreEntry,
 *           this.scopedPathForDisplay → scopedPathForDisplay,
 *           options.isQuotedPrefix → isQuotedPrefix.
 *
 * STATE MODEL (borrowed from upstream):
 *   The built-in provider tracks { commands, basePath, fdPath } on its
 *   instance — created fresh on every session rebind — and re-reads every
 *   ignore file on each fd invocation. This extension mirrors that: tracked
 *   per session = { session cwd, selected source, fd binary name, exclude
 *   path (fd source only) }, built on session_start and reused for the
 *   session; everything else (file listings, ignore-file contents, queries,
 *   scoring) is recomputed per keystroke. Nothing lives at module scope.
 *
 * Notes / limitations:
 * - Probing (rg → fd/fdfind → node) happens once per session. The fd source
 *   resolves your `.git/info/exclude` path once per session too: editing the
 *   file mid-session is picked up instantly (rg/fd re-read it on every run),
 *   but creating it from scratch mid-session needs a `/reload`.
 * - rg lists files only, so empty directories are not completable and
 *   directory entries are derived from file ancestry: they are interleaved
 *   at their path-sorted position (`--sort path`), mirroring fd's sorted
 *   output. Query pre-filtering mirrors fd's in-process pattern (basename
 *   match, smart-case, literal substring). rg honours `.ignore`/`.rgignore` where fd honours
 *   `.ignore`/`.fdignore`; `.gitignore` and git's global excludes are handled
 *   equivalently.
 * - fd's `--ignore-file` patterns are evaluated relative to the search base:
 *   in a scoped `@dir/...` query they root at that dir, so repo-root personal
 *   files may not re-appear in the scoped view. The rg source is git-exact in
 *   every scope, which is why it is the default.
 * - The node walker ignores every ignore rule (it exists so `@` still works
 *   without rg or fd); it shows hidden files and skips `.git`.
 * - If the selected source fails at runtime, the `@` branch returns no
 *   suggestions for that keystroke (upstream behavior); all non-`@`
 *   completion (slash commands, Tab paths) delegates to the built-in provider.
 *
 * Install: drop in ~/.pi/agent/extensions/ (auto-discovered) and `/reload`.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { AutocompleteItem, AutocompleteProvider } from "@earendil-works/pi-tui";
import { spawn } from "node:child_process";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { basename, isAbsolute, join, resolve } from "node:path";

const PATH_DELIMITERS = new Set([" ", "\t", '"', "'", "="]);

function toDisplayPath(value: string): string {
	return value.replace(/\\/g, "/");
}

function escapeRegex(value: string): string {
	return value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function buildFdPathQuery(query: string): string {
	const normalized = toDisplayPath(query);
	if (!normalized.includes("/")) {
		return normalized;
	}

	const hasTrailingSeparator = normalized.endsWith("/");
	const trimmed = normalized.replace(/^\/+|\/+$/g, "");
	if (!trimmed) {
		return normalized;
	}

	const separatorPattern = "[\\\\/]";
	const segments = trimmed
		.split("/")
		.filter(Boolean)
		.map((segment) => escapeRegex(segment));
	if (segments.length === 0) {
		return normalized;
	}

	let pattern = segments.join(separatorPattern);
	if (hasTrailingSeparator) {
		pattern += separatorPattern;
	}
	return pattern;
}

function findLastDelimiter(text: string): number {
	for (let i = text.length - 1; i >= 0; i -= 1) {
		if (PATH_DELIMITERS.has(text[i] ?? "")) {
			return i;
		}
	}
	return -1;
}

function findUnclosedQuoteStart(text: string): number | null {
	let inQuotes = false;
	let quoteStart = -1;

	for (let i = 0; i < text.length; i += 1) {
		if (text[i] === '"') {
			inQuotes = !inQuotes;
			if (inQuotes) {
				quoteStart = i;
			}
		}
	}

	return inQuotes ? quoteStart : null;
}

function isTokenStart(text: string, index: number): boolean {
	return index === 0 || PATH_DELIMITERS.has(text[index - 1] ?? "");
}

function extractQuotedPrefix(text: string): string | null {
	const quoteStart = findUnclosedQuoteStart(text);
	if (quoteStart === null) {
		return null;
	}

	if (quoteStart > 0 && text[quoteStart - 1] === "@") {
		if (!isTokenStart(text, quoteStart - 1)) {
			return null;
		}
		return text.slice(quoteStart - 1);
	}

	if (!isTokenStart(text, quoteStart)) {
		return null;
	}

	return text.slice(quoteStart);
}

function parsePathPrefix(prefix: string): { rawPrefix: string; isAtPrefix: boolean; isQuotedPrefix: boolean } {
	if (prefix.startsWith('@"')) {
		return { rawPrefix: prefix.slice(2), isAtPrefix: true, isQuotedPrefix: true };
	}
	if (prefix.startsWith('"')) {
		return { rawPrefix: prefix.slice(1), isAtPrefix: false, isQuotedPrefix: true };
	}
	if (prefix.startsWith("@")) {
		return { rawPrefix: prefix.slice(1), isAtPrefix: true, isQuotedPrefix: false };
	}
	return { rawPrefix: prefix, isAtPrefix: false, isQuotedPrefix: false };
}

function buildCompletionValue(
	path: string,
	options: { isDirectory: boolean; isAtPrefix: boolean; isQuotedPrefix: boolean },
): string {
	const needsQuotes = options.isQuotedPrefix || path.includes(" ");
	const prefix = options.isAtPrefix ? "@" : "";

	if (!needsQuotes) {
		return `${prefix}${path}`;
	}

	const openQuote = `${prefix}"`;
	const closeQuote = '"';
	return `${openQuote}${path}${closeQuote}`;
}

/**
 * Spawn `bin` with `args`, collect stdout until the process exits or
 * `onChunk` reports the cap (the child is then killed). Always resolves;
 * callers interpret `signal.aborted`, `exitCode` and `truncated` themselves,
 * since fd's exit-code-0 requirement and rg's cap-kill keep their own rules.
 */
type CollectedRun = { stdout: string; exitCode: number | null; truncated: boolean };

async function collectProcessOutput(
	bin: string,
	args: string[],
	signal: AbortSignal,
	options: { cwd?: string; onChunk?: (chunk: string) => boolean } = {},
): Promise<CollectedRun> {
	return await new Promise((resolveRun) => {
		if (signal.aborted) {
			resolveRun({ stdout: "", exitCode: null, truncated: false });
			return;
		}

		const child = spawn(bin, args, {
			cwd: options.cwd,
			stdio: ["ignore", "pipe", "pipe"],
		});
		let stdout = "";
		let truncated = false;
		let resolved = false;

		const finish = (run: CollectedRun) => {
			if (resolved) return;
			resolved = true;
			signal.removeEventListener("abort", onAbort);
			resolveRun(run);
		};

		const onAbort = () => {
			if (child.exitCode === null) {
				child.kill("SIGKILL");
			}
		};

		signal.addEventListener("abort", onAbort, { once: true });
		child.stdout.setEncoding("utf-8");
		child.stdout.on("data", (chunk: string) => {
			stdout += chunk;
			if (!truncated && options.onChunk?.(chunk)) {
				truncated = true;
				child.kill("SIGKILL");
			}
		});
		child.on("error", () => finish({ stdout, exitCode: null, truncated }));
		child.on("close", (code) => finish({ stdout, exitCode: code, truncated }));
	});
}

async function walkDirectoryWithFd(
	baseDir: string,
	fdPath: string,
	query: string,
	maxResults: number,
	signal: AbortSignal,
	extraArgs: string[] = [],
): Promise<Array<{ path: string; isDirectory: boolean }>> {
	const args = [
		"--base-directory",
		baseDir,
		"--max-results",
		String(maxResults),
		"--type",
		"f",
		"--type",
		"d",
		"--follow",
		"--hidden",
		"--exclude",
		".git",
		"--exclude",
		".git/*",
		"--exclude",
		".git/**",
		...extraArgs,
	];

	if (toDisplayPath(query).includes("/")) {
		args.push("--full-path");
	}

	if (query) {
		args.push(buildFdPathQuery(query));
	}

	const run = await collectProcessOutput(fdPath, args, signal);
	if (signal.aborted || run.exitCode !== 0 || !run.stdout) {
		return [];
	}

	const lines = run.stdout.trim().split("\n").filter(Boolean);
	const results: Array<{ path: string; isDirectory: boolean }> = [];

	for (const line of lines) {
		const displayLine = toDisplayPath(line);
		const hasTrailingSeparator = displayLine.endsWith("/");
		const normalizedPath = hasTrailingSeparator ? displayLine.slice(0, -1) : displayLine;
		if (normalizedPath === ".git" || normalizedPath.startsWith(".git/") || normalizedPath.includes("/.git/")) {
			continue;
		}

		results.push({
			path: displayLine,
			isDirectory: hasTrailingSeparator,
		});
	}

	return results;
}

function extractAtPrefix(text: string): string | null {
	const quotedPrefix = extractQuotedPrefix(text);
	if (quotedPrefix?.startsWith('@"')) {
		return quotedPrefix;
	}

	const lastDelimiterIndex = findLastDelimiter(text);
	const tokenStart = lastDelimiterIndex === -1 ? 0 : lastDelimiterIndex + 1;

	if (text[tokenStart] === "@") {
		return text.slice(tokenStart);
	}

	return null;
}

function expandHomePath(path: string): string {
	if (path.startsWith("~/")) {
		const expandedPath = join(homedir(), path.slice(2));
		// Preserve trailing slash if original path had one
		return path.endsWith("/") && !expandedPath.endsWith("/") ? `${expandedPath}/` : expandedPath;
	} else if (path === "~") {
		return homedir();
	}
	return path;
}

function resolveScopedFuzzyQuery(
	rawQuery: string,
	basePath: string,
): { baseDir: string; query: string; displayBase: string } | null {
	const normalizedQuery = toDisplayPath(rawQuery);
	const slashIndex = normalizedQuery.lastIndexOf("/");
	if (slashIndex === -1) {
		return null;
	}

	const displayBase = normalizedQuery.slice(0, slashIndex + 1);
	const query = normalizedQuery.slice(slashIndex + 1);

	let baseDir: string;
	if (displayBase.startsWith("~/")) {
		baseDir = expandHomePath(displayBase);
	} else if (displayBase.startsWith("/")) {
		baseDir = displayBase;
	} else {
		baseDir = join(basePath, displayBase);
	}

	try {
		if (!statSync(baseDir).isDirectory()) {
			return null;
		}
	} catch {
		return null;
	}

	return { baseDir, query, displayBase };
}

function scopedPathForDisplay(displayBase: string, relativePath: string): string {
	const normalizedRelativePath = toDisplayPath(relativePath);
	if (displayBase === "/") {
		return `/${normalizedRelativePath}`;
	}
	return `${toDisplayPath(displayBase)}${normalizedRelativePath}`;
}

function scoreEntry(filePath: string, query: string, isDirectory: boolean): number {
	const fileName = basename(filePath);
	const lowerFileName = fileName.toLowerCase();
	const lowerQuery = query.toLowerCase();

	let score = 0;

	if (lowerFileName === lowerQuery) score = 100;
	else if (lowerFileName.startsWith(lowerQuery)) score = 80;
	else if (lowerFileName.includes(lowerQuery)) score = 50;
	else if (filePath.toLowerCase().includes(lowerQuery)) score = 30;

	// Directories get a bonus to appear first
	if (isDirectory && score > 0) score += 10;

	return score;
}

type CandidateEntry = { path: string; isDirectory: boolean };

function rankAndFormatFuzzyEntries(
	entries: CandidateEntry[],
	fdQuery: string,
	scopedQuery: { baseDir: string; query: string; displayBase: string } | null,
	isQuotedPrefix: boolean,
): AutocompleteItem[] {
	const scoredEntries = entries
		.map((entry) => ({
			...entry,
			score: fdQuery ? scoreEntry(entry.path, fdQuery, entry.isDirectory) : 1,
		}))
		.filter((entry) => entry.score > 0);

	scoredEntries.sort((a, b) => b.score - a.score);
	const topEntries = scoredEntries.slice(0, 20);

	const suggestions: AutocompleteItem[] = [];
	for (const { path: entryPath, isDirectory } of topEntries) {
		const pathWithoutSlash = isDirectory ? entryPath.slice(0, -1) : entryPath;
		const displayPath = scopedQuery
			? scopedPathForDisplay(scopedQuery.displayBase, pathWithoutSlash)
			: pathWithoutSlash;
		const entryName = basename(pathWithoutSlash);
		const completionPath = isDirectory ? `${displayPath}/` : displayPath;
		const value = buildCompletionValue(completionPath, {
			isDirectory,
			isAtPrefix: true,
			isQuotedPrefix,
		});

		suggestions.push({
			value,
			label: entryName + (isDirectory ? "/" : ""),
			description: displayPath,
		});
	}

	return suggestions;
}

/**
 * A source of base-relative candidate entries for `@` attachments. Each
 * implementation encapsulates the ignore semantics of its underlying tool;
 * the shared rankAndFormatFuzzyEntries() applies the final query threshold.
 */
interface FileCandidateSource {
	/** Short label for diagnostics ("rg" | "fd" | "node"). */
	readonly name: string;
	/**
	 * Produce candidate paths relative to `base` that may be offered as `@`
	 * completions. Sources pre-filter by `query` where they can. Must never
	 * reject on `signal` abort.
	 */
	getCandidates(params: {
		base: string;
		query: string;
		signal: AbortSignal;
	}): Promise<CandidateEntry[]>;
}

/** Cap for the rg fallback and the node walker (mirrors fd --max-results). */
const ENUMERATION_CAP = 20_000;

/**
 * Default source: `--no-ignore-exclude` disables only the manually configured
 * excludes (`.git/info/exclude`) while `.gitignore` rules stay in effect —
 * exactly the A ∪ (B ∖ C) semantics in one pass. rg lists files only, so
 * directories are derived from file paths to keep `@dir/...` drilling working;
 * `--sort path` reproduces fd's path-sorted output order.
 */
const rgSource: FileCandidateSource = {
	name: "rg",
	async getCandidates({ base, query, signal }) {
		let lineCount = 0;
		const run = await collectProcessOutput(
			"rg",
			[
				"--files",
				"--hidden",
				"-L",
				"--no-ignore-exclude",
				"--glob",
				"!.git",
				"--glob",
				"!.git/**",
				"--sort",
				"path",
			],
			signal,
			{
				// cwd=base makes output paths base-relative.
				cwd: base,
				onChunk: (chunk) => {
					lineCount += chunk.match(/\n/g)?.length ?? 0;
					// fd's --max-results equivalent: stop the walk once the cap
					// is reached instead of buffering a huge tree.
					return lineCount >= ENUMERATION_CAP;
				},
			},
		);
		if (signal.aborted) {
			return [];
		}
		const lines = run.stdout.split("\n");
		if (run.truncated && !run.stdout.endsWith("\n")) {
			lines.pop(); // killed mid-record: drop the partial trailing line
		}
		const files = lines
			.filter(Boolean)
			.slice(0, ENUMERATION_CAP)
			.filter((line) => {
				const displayLine = toDisplayPath(line);
				return !(displayLine === ".git" || displayLine.startsWith(".git/") || displayLine.includes("/.git/"));
			});
		// Mirror fd's in-process pattern: basename only, smart-case, literal
		// substring. rg itself takes no pattern here.
		const smartCase = /[A-Z]/.test(query);
		const needle = query ? (smartCase ? query : query.toLowerCase()) : null;
		const basenameMatches = (path: string) => {
			if (needle === null) {
				return true;
			}
			const base = path.slice(path.lastIndexOf("/") + 1);
			return (smartCase ? base : base.toLowerCase()).includes(needle);
		};
		// Walk paths in sorted order and surface each matching dir the first
		// time it is crossed as an ancestor: this reproduces fd's interleaving
		// of directories with their contents (a dir sorts directly before the
		// first file under it). A dir is offered when its own basename matches
		// the query, so `@loc` still offers `.local/` like upstream fd would.
		const emittedDirs = new Set<string>();
		const results: CandidateEntry[] = [];
		for (const file of files) {
			const ancestors: string[] = [];
			let slash = file.lastIndexOf("/");
			while (slash > 0) {
				const dir = file.slice(0, slash);
				if (basenameMatches(dir) && !emittedDirs.has(dir)) {
					ancestors.push(dir);
					emittedDirs.add(dir);
				}
				slash = dir.lastIndexOf("/");
			}
			for (let i = ancestors.length - 1; i >= 0; i -= 1) {
				results.push({ path: `${ancestors[i]}/`, isDirectory: true });
			}
			if (basenameMatches(file)) {
				results.push({ path: toDisplayPath(file), isDirectory: false });
			}
		}
		return results;
	},
};

/**
 * fd fallback: pass A (verbatim upstream walk) plus passes B and C to re-add
 * the files git's `info/exclude` hides. Requires the exclude path, resolved
 * once per session; without it (no repo / no rules) it degenerates to pass A,
 * i.e. exactly the built-in behavior.
 */
function createFdSource(bin: string, excludePath: string | null): FileCandidateSource {
	return {
		name: "fd",
		async getCandidates({ base, query, signal }) {
			const runA = await walkDirectoryWithFd(base, bin, query, 100, signal);
			if (signal.aborted) {
				return [];
			}
			if (!excludePath) {
				return runA;
			}
			const [runB, runC] = await Promise.all([
				walkDirectoryWithFd(base, bin, query, 8_000, signal, ["--no-ignore-vcs"]),
				walkDirectoryWithFd(base, bin, query, 8_000, signal, [
					"--no-ignore-vcs",
					"--ignore-file",
					excludePath,
				]),
			]);
			if (signal.aborted) {
				return [];
			}
			// extras = B ∖ C: files ignored by info/exclude and nothing else.
			const setB = new Set(runB.map((entry) => entry.path));
			const setC = new Set(runC.map((entry) => entry.path));
			const setA = new Set(runA.map((entry) => entry.path));
			const extras = runB.filter((entry) => !setC.has(entry.path) && !setA.has(entry.path));
			return [...runA, ...extras];
		},
	};
}

/**
 * Last resort: a plain readdir walk (no ignore rules, hidden files included,
 * `.git` skipped) so `@` still completes when neither rg nor fd is present.
 */
const walkSource: FileCandidateSource = {
	name: "node",
	async getCandidates({ base, query, signal }) {
		const entries: CandidateEntry[] = [];
		const stack: string[] = [""];
		while (stack.length > 0) {
			if (signal.aborted) {
				break;
			}
			const relDir = stack.pop()!;
			const absDir = relDir ? join(base, relDir) : base;
			let list;
			try {
				list = readdirSync(absDir, { withFileTypes: true });
			} catch {
				continue;
			}
			for (const entry of list) {
				const rel = relDir ? `${relDir}/${entry.name}` : entry.name;
				if (entry.name === ".git") {
					continue;
				}
				if (entry.isDirectory()) {
					entries.push({ path: `${rel}/`, isDirectory: true });
					stack.push(rel);
				} else {
					entries.push({ path: rel, isDirectory: false });
				}
				if (entries.length >= ENUMERATION_CAP) {
					return entries;
				}
			}
		}
		return entries;
	},
};

/**
 * Resolve the session's personal exclude file once per session; null when
 * there is nothing to do (not a git repo, or info/exclude carries no rules) —
 * the fd source then degenerates to stock behavior. `--git-path` resolves
 * through the common git dir, so linked worktrees point at the repo's real
 * exclude file rather than the worktree metadata dir.
 */
async function resolveExcludeFile(pi: ExtensionAPI, cwd: string): Promise<string | null> {
	try {
		const result = await pi.exec("git", ["rev-parse", "--git-path", "info/exclude"], { cwd, timeout: 3_000 });
		if (result.code !== 0 || !result.stdout) {
			return null;
		}
		const candidate = result.stdout.trim().split("\n")[0];
		if (!candidate) {
			return null;
		}
		const absCandidate = isAbsolute(candidate) ? candidate : resolve(cwd, candidate);
		if (!existsSync(absCandidate)) {
			return null;
		}
		const content = readFileSync(absCandidate, "utf8");
		const hasRules = content.split("\n").some((line) => {
			const trimmed = line.trim();
			return trimmed.length > 0 && !trimmed.startsWith("#");
		});
		return hasRules ? absCandidate : null;
	} catch {
		return null;
	}
}

async function hasBinary(pi: ExtensionAPI, name: string): Promise<boolean> {
	try {
		const result = await pi.exec(name, ["--version"], { timeout: 3_000 });
		return result.code === 0;
	} catch {
		return false;
	}
}

/** Prefer rg, then fd (or Debian's fdfind), then the node walker. */
async function pickSource(pi: ExtensionAPI, cwd: string): Promise<FileCandidateSource> {
	if (await hasBinary(pi, "rg")) {
		return rgSource;
	}
	for (const bin of ["fd", "fdfind"]) {
		if (await hasBinary(pi, bin)) {
			return createFdSource(bin, await resolveExcludeFile(pi, cwd));
		}
	}
	return walkSource;
}

/** Control flow port of the built-in getFuzzyFileSuggestions(), with the
 *  walk replaced by the session's candidate source. */
async function getFuzzyItems(
	source: FileCandidateSource,
	basePath: string,
	rawPrefix: string,
	isQuotedPrefix: boolean,
	signal: AbortSignal,
): Promise<AutocompleteItem[]> {
	if (signal.aborted) {
		return [];
	}
	try {
		const scopedQuery = resolveScopedFuzzyQuery(rawPrefix, basePath);
		const fdBaseDir = scopedQuery?.baseDir ?? basePath;
		const fdQuery = scopedQuery?.query ?? rawPrefix;
		const entries = await source.getCandidates({ base: fdBaseDir, query: fdQuery, signal });
		if (signal.aborted) {
			return [];
		}
		return rankAndFormatFuzzyEntries(entries, fdQuery, scopedQuery, isQuotedPrefix);
	} catch {
		return [];
	}
}

function createCompleterProvider(
	current: AutocompleteProvider,
	pi: ExtensionAPI,
	cwd: string,
): AutocompleteProvider {
	// Session-tracked state, mirroring the built-in provider's
	// { basePath, fdPath } constructor fields: resolved lazily on first @ use,
	// rebuilt on every session rebind (session_start re-registers the provider
	// and pi clears the wrapper list).
	let sourcePromise: Promise<FileCandidateSource> | null = null;
	const getSource = () => (sourcePromise ??= pickSource(pi, cwd));

	return {
		async getSuggestions(lines, cursorLine, cursorCol, options) {
			const currentLine = lines[cursorLine] || "";
			const textBeforeCursor = currentLine.slice(0, cursorCol);
			const atPrefix = extractAtPrefix(textBeforeCursor);
			if (!atPrefix) {
				return current.getSuggestions(lines, cursorLine, cursorCol, options);
			}
			// Same branch as the built-in getSuggestions() @-case.
			const { rawPrefix, isQuotedPrefix } = parsePathPrefix(atPrefix);
			const source = await getSource();
			const suggestions = await getFuzzyItems(source, cwd, rawPrefix, isQuotedPrefix, options.signal);
			if (suggestions.length === 0) {
				return null;
			}
			return { items: suggestions, prefix: atPrefix };
		},

		applyCompletion(lines, cursorLine, cursorCol, item, prefix) {
			return current.applyCompletion(lines, cursorLine, cursorCol, item, prefix);
		},

		shouldTriggerFileCompletion(lines, cursorLine, cursorCol) {
			return current.shouldTriggerFileCompletion?.(lines, cursorLine, cursorCol) ?? true;
		},
	};
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		const cwd = ctx.cwd;
		ctx.ui.addAutocompleteProvider((current) => createCompleterProvider(current, pi, cwd));
	});
}