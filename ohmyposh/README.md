## Migrating
Make sure the `version` is up-to-date; otherwise, the [config will be migrated when loaded](https://github.com/JanDeDobbeleer/oh-my-posh/blob/9abd87a181d87015ecbc3f7283ec65f1ae929b7c/src/config/load.go#L31), re-ordering segments and formatting strings, which may be annoying.

If you want to migrate manually, run `oh-my-posh config migrate --config <config path> --format <format>`; this may be useful if a dogmatic format is desired.

## Taplo
For some reason, the Taplo config file (`./.taplo.toml`) isn't excluded from the schema that it sets. As a result, it uses a basic rule to set that and excludes itself.
