# [Kitty](https://sw.kovidgoyal.net/kitty/)
## Wrappers
Kitty offers several conveniences for shell integration, such as foor over SSH. Wrappers have been written using the [`run-shell` kitten](https://sw.kovidgoyal.net/kitty/shell-integration/#using-shell-integration-in-sub-shells-containers-etc) for shells with integration support, with a wrapper for the [`ssh` kitten](https://sw.kovidgoyal.net/kitty/kittens/ssh/) as well. These wrappers are prepended to the `PATH` by Kitty itself with the `env` keyword:
```sh
env PATH=${XDG_CONFIG_HOME}/kitty/wrappers/:${PATH}
```
**Note**: It's very brittle right now. The assumption is that `/bin/sh` points to a shell which supports `printf '%q'`; I cannot point at Bash directly, otherwise it will run itself and hang. A more comprehensive approach to splitting the shell launch parameters is needed.
