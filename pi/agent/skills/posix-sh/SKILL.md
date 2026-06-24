---
name: posix-sh
description: Write a POSIX shell-compliant script with a set of compliance rules and tests.
---

# POSIX Shell

Write a POSIX-compliant shell script which fulfills the user's needs.

## POSIX Shell Hygeine
- No `[[ ]]`, `<( )`, `source`, `local`, arrays, `=~`, `${!var}`, `${var^}`, `echo -e/-n` (use `printf`), etc.
- Prefer `printf` over `echo`. Use `>&2` for error messages.
- Use `set -eu` (or `set -o nounset -o errexit`) unless the script legitimately needs to handle errors manually. 
- Use `trap` for cleanup where appropriate.
- Use a `while getopts` loop (POSIX `getopts`). Do not use `getopt(1)`.
- Prefer built-in string manipulation tooling over external tool calls, e.g. prefix/suffix glob removals (`#`/`##`/`%`/`%%`).

## Mandatory Validation Loop

After writing the initial script, run `nix run 'nixpkgs#shellcheck' -- -Cnever -s sh -f gcc '<script path>'` to check the script for POSIX compliance; apply needed fixes and check again until errors are cleared.

If you need more clarification about how to fix a problem noted by Shellcheck--e.g. finding POSIX alternatives to a Bash-only approach--you can view the wiki page for a problem:

```sh
CODE="3010" curl -sSL https://github.com/koalaman/shellcheck/wiki/SC${CODE#SC}.md
```

Warnings should generally be fixed; however, there *are* scenarios where warnings don't apply. An example is modifying an existing variable in a sub-shell; shellcheck will warn about this, often correctly, but there are legitimate scenarios where this is useful. Consider the warning and how it applies to your specific case.

Format the document with `shfmt <script path>` when you are done.
