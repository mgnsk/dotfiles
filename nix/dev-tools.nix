{ pkgs, username, ... }:
{
  programs.github-copilot-cli = {
    enable = true;
    package = pkgs.github-copilot-cli;

    # Matches the pre-existing config location; the module
    # defaults to ~/.copilot instead of the XDG config dir.
    configDir = "/home/${username}/.config/copilot";

    settings = {
      theme = "auto";
      banner = "never";
    };
  };

  # No `settings` block - the module always writes
  # ~/.claude/settings.json as a read-only store symlink with no
  # mutable option, which breaks anything Claude Code itself needs
  # to write there (/effort, /theme, /plugin, ...). Left for the
  # CLI to own outright; set theme/notifications/plugins once by
  # hand after switching.
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
  };

  # No home-manager module for luacheck; verbatim Lua, not data.
  xdg.configFile."luacheck/.luacheckrc".text = # lua
    ''
      globals = { "vim" }
    '';

  # Consumed by .scripts/bin/sandbox, which bind-mounts these by
  # literal path into /etc/claude-code/ inside the sandbox
  # namespace - unrelated to programs.claude-code's own settings
  # (~/.claude/), so path must stay exactly as-is.
  xdg.configFile."claude-code-managed/managed-mcp.json".source =
    (pkgs.formats.json { }).generate "claude-code-managed-mcp.json"
      {
        mcpServers.mcp-nixos = {
          type = "stdio";
          command = "mcp-nixos";
          args = [ ];
        };
      };

  xdg.configFile."claude-code-managed/managed-settings.json".source =
    (pkgs.formats.json { }).generate "claude-code-managed-settings.json"
      {
        attribution.sessionUrl = false;
        env.DISABLE_AUTOUPDATER = 1;
        permissions.allow = [
          "mcp__mcp-nixos__nix"
          "mcp__mcp-nixos__nix_versions"
        ];
      };

  home.file.".config/yamllint/config".source = (pkgs.formats.yaml { }).generate "yamllint-config" {
    "yaml-files" = [
      "*.yaml"
      "*.yml"
      ".yamllint"
    ];

    rules = {
      anchors = "enable";
      braces = "enable";
      brackets = "enable";
      colons = "enable";
      commas = "enable";
      comments = {
        require-starting-space = true;
        ignore-shebangs = true;
        min-spaces-from-content = 1;
      };
      comments-indentation.level = "warning";
      document-end = "disable";
      document-start.level = "warning";
      empty-lines = "enable";
      empty-values = "disable";
      float-values = "disable";
      hyphens = "enable";
      indentation = {
        spaces = "consistent";
        indent-sequences = "consistent";
        check-multi-line-strings = false;
      };
      key-duplicates = "enable";
      key-ordering = "disable";
      line-length = "disable";
      new-line-at-end-of-file = "enable";
      new-lines = "enable";
      octal-values = "disable";
      quoted-strings = "disable";
      trailing-spaces = "enable";
      truthy.level = "warning";
    };
  };

  home.file."revive.toml".source = (pkgs.formats.toml { }).generate "revive.toml" {
    ignoreGeneratedHeader = false;
    severity = "warning";
    confidence = 0.8;
    errorCode = 0;
    warningCode = 0;

    rule = {
      context-keys-type = { };
      time-naming = { };
      var-declaration = { };
      unexported-return = { };
      errorf = { };
      blank-imports = { };
      context-as-argument = { };
      error-return = { };
      error-strings = { };
      error-naming = { };
      exported = { };
      if-return = { };
      increment-decrement = { };
      var-naming = { };
      package-comments = { };
      range = { };
      receiver-naming = { };
      indent-error-flow = { };
      cyclomatic.arguments = [ 30 ];
      empty-block = { };
      superfluous-else = { };
      confusing-naming = { };
      get-return = { };
      confusing-results = { };
      deep-exit = { };
      unused-parameter = { };
      unreachable-code = { };
      flag-parameter = { };
      unnecessary-stmt = { };
      struct-tag = { };
      modifies-value-receiver = { };
      constant-logical-expr = { };
      bool-literal-in-expr = { };
      redefines-builtin-id = { };
      range-val-in-closure = { };
      range-val-address = { };
      waitgroup-by-value = { };
      atomic = { };
      call-to-gc = { };
      duplicated-imports = { };
      import-shadowing = { };
      unused-receiver = { };
      unhandled-error = { };
      cognitive-complexity.arguments = [ 30 ];
      string-of-int = { };
      early-return = { };
      unconditional-recursion = { };
      identical-branches = { };
      defer = { };
      unexported-naming = { };
    };
  };
}
