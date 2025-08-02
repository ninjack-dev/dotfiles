# [Kitty](https://sw.kovidgoyal.net/kitty/)
## Wrappers
Kitty offers several conveniences for shell integration, such as foor over SSH. Wrappers have been written using the [`run-shell` kitten](https://sw.kovidgoyal.net/kitty/shell-integration/#using-shell-integration-in-sub-shells-containers-etc) for shells with integration support, with a wrapper for the [`ssh` kitten](https://sw.kovidgoyal.net/kitty/kittens/ssh/) as well. These wrappers are prepended to the `PATH` by Kitty itself with the `env` keyword:
```sh
env PATH=${XDG_CONFIG_HOME}/kitty/wrappers/:${PATH}
```
