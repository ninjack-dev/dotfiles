---
name: github
description: Any time you interact with *anything* on GitHub, such as code, comments, or the like, you *must* refer to this skill.
---

# GitHub

`gh` is installed and authenticated. Use it for all GitHub interaction — never raw `curl` or scraped HTML. Everything prints to stdout: read it straight into context, or filter first so context stays light and focused.

## Target a repo
- Subcommands accept `-R owner/repo`; `gh api` doesn't — pass the full `repos/{owner}/{repo}/...` path instead.
- Don't guess branch names. Read the default (`gh api repos/{owner}/{repo} --jq .default_branch`) or use `HEAD` in API paths.
- `export GH_REPO=owner/repo` to set a default for subcommands.

## Reading source code
- Raw file body: `gh api repos/{owner}/{repo}/contents/{path} -H "Accept: application/vnd.github.raw"` — add `?ref={branch}` for a non-default branch.
- Whole-repo file list: `gh api "repos/{owner}/{repo}/git/trees/HEAD?recursive=1" --jq '.tree[].path'`.
- Directory listing: `gh api repos/{owner}/{repo}/contents/{dir} --jq '.[].name'`.
- Code search: `gh search code "{query}" -R owner/repo`.

## Issues & PRs
- `gh issue view {n} -R owner/repo` — state, title, body. `--comments` adds the thread.
- `gh pr view {n} -R owner/repo` — same for PRs; `gh pr diff {n}` for the changes.
- `gh issue list` / `gh pr list` — open items; add `--state all`, `--search "..."`, `--limit N`.
- `gh search issues "{query}"` — cross-repo issue/PR search.

## Keep output small
- Prefer JSON and extract with `--jq '...'` (jq) or `--template '...'` (Go templates), e.g. `gh issue view {n} --json number,title,state,body`.
- Pipe long results through `head` when a sample suffices.
- `--paginate` on big endpoints, but always filter with `--jq` after — volume can explode.

## Errors
- 404: wrong owner/repo, branch, or path — or a private repo this account can't see. Verify with `gh api repos/{owner}/{repo}` before concluding the repo doesn't exist.
- Rate limits: authenticated `gh` gets 5,000 req/hr and search endpoints are 10/min, so batch queries where possible.
