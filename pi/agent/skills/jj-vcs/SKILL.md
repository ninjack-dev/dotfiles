---
name: jj-vcs
description: Use the Jujutsu VCS (jj) CLI effectively via systematic help exploration to implement a VCS goal presented by the user.
---

# Jujutsu VCS (`jj`) — Exploration & Execution Protocol

When a user asks you to perform a VCS task using `jj`, follow this protocol to first understand the `jj` model, then discover the right commands via its help system, and finally construct an executable plan.

## 1. Protocol Overview

These steps should be followed in order:

1. **Prime** — Understand the mental model: changes, revisions, bookmarks, the operation log, and how `jj` differs from Git.
2. **Decompose** — Break the user's high-level request into concrete VCS operations, using `jj` concepts.
3. **Discover** — For each operation, use `jj help <command>`, `jj help -k <keyword>`, and `jj-glossary` to find exact flags and semantics.
4. **Plan** — Sequence the commands with precondition checks before and verification after each step.
5. **Propose** — Connect each command back to `jj` concepts so the user understands the *why*, not just the *what*. Wait for approval.
6. **Execute** — Run the commands and check results.

## 2. Task Decomposition

Decompose the user's freeform request into concrete VCS operations. Common
categories of operations (discover the exact commands in step 3):

- Creating / starting work on changes
- Describing / saving progress
- Moving changes between commits (squash, rebase)
- Reorganising history (rebase, split, abandon)
- Undoing / restoring
- Working with remotes (fetch, push)
- Managing bookmarks
- Resolving conflicts
- Inspecting history (log, diff, evolog, bisect)

For each category, use help discovery (step 3) to find the right command and
its flags — do not rely on memorised command patterns.

## 3. Help Discovery

### `jj help` commands

```sh
# List all top-level commands
jj help

# Full help for any command (read the whole page — nuance matters)
jj help <command>
jj help <command> <subcommand>

# Conceptual keyword help
jj help -k <keyword>
```

### Available keywords for `jj help -k`

| Keyword | Content | When to consult |
| ------- | ------- | ----------------|
| `bookmarks` | How bookmarks work: tracking, pushing, conflicts, mapping to Git branches | Before push/fetch or bookmark operations |
| `revsets` | The revision-selection language (symbols, operators, functions) | Before any `-r` / `--revisions` flag |
| `templates` | Customising output with `-T` / `--template` | When user wants customised log/diff output |
| `filesets` | Selecting files with expressions | Before `jj diff <fileset>` or `jj squash <fileset>` |
| `config` | Configuration settings | Before modifying `jj` behaviour via config |
| `tutorial` | Full tutorial (assumes Git knowledge) | For comprehensive understanding; this is heavy, and a last resort to boost understanding |

### jj-glossary (colocated tool)

```sh
# List all glossary terms
./jj-glossary

# Look up specific terms (case-insensitive, multi-word OK)
./jj-glossary 'Conflict' 'Revset' 'Working copy'
```

### Searching help output

When you need a specific option, examine the help text directly:

```sh
jj help rebase
```

Always read the surrounding paragraphs — `jj`'s help is dense but every detail matters. Do not truncate context with `head -N` or `grep -A N`. Do not guess flag semantics; you must look them up.

## 4. Planning & Verification

Sequence operations with a consistent pattern:

1. **Precondition check** — inspect current state (`jj st`, `jj log -r <revset>`, etc.)
2. **Execute** — the `jj` command(s)
3. **Verify** — confirm the result (re-run `jj log`, `jj diff`, etc.)

## 5. Rules

1. **Check `jj st` before destructive operations** — the working copy is a real commit; know its state before rewriting.

2. **Never use `--ignore-immutable` unless the user gives explicit permission** — by default `jj` protects `trunk() | tags() | untracked_remote_bookmarks()`. Overriding can rewrite shared history.

3. **Prefer change IDs over commit IDs** — change IDs survive rewrites; commit IDs change after rebase / squash.

4. **Never push to the remote** — this is a user responsibility.

5. **Conflicts are not errors** — `jj` rebases through conflicts. They're first-class objects. Resolve them when convenient via `jj resolve`.

6. **Use canonical command names** in scripts and explanations — aliases exist but prefer the full names (`jj status` not `jj st` in shared context).

## Implementation Notes

- `jj help` output includes terminal formatting (ANSI codes). Strip or tolerate
  them when parsing programmatically.
- `jj` subcommand aliases are noted in `help` output (e.g. `[aliases: st]`).
- When showing the user a command, show its output too — they need to see how
  `jj` responds.
