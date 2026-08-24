{
  ...
}:
{
  security.polkit = {
    enable = true;
    extraConfig = (builtins.readFile ./rules.js);
  };
}
