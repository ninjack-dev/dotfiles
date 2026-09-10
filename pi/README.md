## Pi

The `pi` CLI is not managed by NixOS; I want to stay on the bleeding edge with minimal downtime. Its config is stored in `XDG_CONFIG_HOME` and symlinked to `.pi`, with ignore patterns for state files[^1].

```sh
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
ln -s "$XDG_CONFIG_HOME/pi" "$HOME/.pi"
# Temporary; some extensions are using packages from Pi's dependency tree. 
# This was the easiest (and stupidest) way to hoist them without deduping
ln -s \
    "$(npm list -g @earendil-works/pi-coding-agent --parseable)" \
    "$HOME/.pi/agent/extensions/node_modules"
```

[^1]: Requests have been made upstream ([#2870](https://github.com/earendil-works/pi/issues/2870), [#5301](https://github.com/earendil-works/pi/issues/5301), both closed) to implement the XDG spec for separating config/state, but they have been largely rejected by [Mario](https://github.com/badlogic) for whatever reason.
