---
description: Create a POSIX-compliant shell script with validation via shellcheck
argument-hint: "<purpose> [options-description]"
---
Create a POSIX-compliant shell script for the following purpose:

$1

${2:+Options/arguments: $2}

## POSIX Shell Hygeine
- No `[[ ]]`, `<( )`, `source`, `local`, arrays, `=~`, `${!var}`, `${var^}`, `echo -e/-n` (use `printf`), etc.
- Prefer `printf` over `echo`. Use `>&2` for error messages.
- Use `set -eu` (or `set -o nounset -o errexit`) unless the script legitimately needs to handle errors manually. 
- Use `trap` for cleanup where appropriate.
- Use a `while getopts` loop (POSIX `getopts`). Do not use `getopt(1)`.

## Mandatory Validation Loop

You **must** follow this exact cycle until the script is clean:

### 1. Write/Modify the script

Write the script to a file using the `write` tool.

### 2. Check Your Work

After writing the initial script, run `nix run 'nixpkgs#shellcheck' -- -Cnever -s sh -f gcc '<script path>'` to check the script for POSIX compliance; apply needed fixes and check again until errors are cleared.

```
$ nix run 'nixpkgs#shellcheck' -- -Cnever -s sh -f gcc '/tmp/script.sh'
/tmp/script.sh:1:1: warning: In POSIX sh, [[ ]] is undefined. [SC3010]
```

If you need more clarification about how to fix a problem noted by Shellcheck--e.g. finding POSIX alternatives to a Bash-only approach--you can view the wiki page for a problem:

```sh
CODE="3010" curl -sSL https://github.com/koalaman/shellcheck/wiki/SC${CODE#SC}.md
```

Warnings are generally to be fixed; however, there *are* scenarios where warnings don't apply. An example is modifying an existing variable in a sub-shell; shellcheck will warn about this, often correctly, but there are legitimate scenarios for doing this.

---

Format the document with `shfmt` when you are done.
