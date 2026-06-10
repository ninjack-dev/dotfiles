## Pi

The `pi` CLI is not managed by NixOS; I want to stay on the bleeding edge with minimal downtime. Its config is stored in `XDG_CONFIG_HOME` and symlinked to `.pi`, with ignore patterns for state files. 

Requests have been made upstream ([#2870](https://github.com/earendil-works/pi/issues/2870), [#5301](https://github.com/earendil-works/pi/issues/5301), both closed) to implement the XDG spec for separating config/state, but they have been largely rejected by [Mario](https://github.com/badlogic) for whatever reason.

```sh
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
ln -s "$XDG_CONFIG_HOME/pi" "$HOME/.pi"
```
