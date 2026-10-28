# rushi/default.nix — the declarative rushi config.
#
# Consumer-side data (the nixvim-config/default.nix shape): one
# NixOS-style module that sets the rushi.* options. The values
# are the personal deployment that used to live in the
# rushi-config repo data module (pre-refactor
# config/rushi-config.nix), moved here: the consumer owns the
# config, the flake only assembles.
#
# The builder-owned fields are not set here: the ext packages
# (rushi.external_*) come from the flake's exts table
# (rushi/exts.nix), and the TUI binary (rushi.tui) is wired by
# the builder.

{
  # The bash-only native tool catalog (the 2026-10-06
  # decision: the lean variant is retired, bash is the only
  # native tool this deployment exposes).
  rushi.tools = [ "bash" ];

  rushi.config = {
    # [active]
    active = {
      model = "Qwen3.8-27B-NVFP4-RTX5090-DFlash2";
    };

    # [model]
    model = {
      "Qwen3.8-27B-NVFP4-RTX5090-DFlash2" = {
        api_key_env = "LLAMA_API_KEY";
        base_url = "http://127.0.0.1:30000";
        context_tokens = 262144;
        model_id = "Qwen3.8-27B-NVFP4-RTX5090-v2";
        vision = true;
      };
      api = "responses";
      max_output_tokens = 65536;
      reasoning_effort = "xhigh";
    };

    # [limits]
    limits = {
      bash_timeout_max = 600;
      compact_enabled = true;
      compact_keep_tokens = 20000;
      compact_reserve_tokens = 16384;
      compact_strategy = "compact";
      context_budget_tokens = 262144;
    };

    # [hooks] — the full pipeline: kernel-shipped + ext hooks.
    # The ext hook binaries are bundled by the flake's exts
    # table, so the kernel's build-time drift guard resolves
    # every command.
    hooks = {
      timeout_ms = 30000;

      # One [hooks.defs.<name>] entry per hook (8 total).
      defs = {
        # Kernel-shipped (bundled by the kernel in bin/).
        "harness-hook-compact".command = "harness-hook-compact";
        "harness-hook-no-long-sleep".command =
          "harness-hook-no-long-sleep";
        # Goal-continuation hooks (rushi-goal-mode).
        "harness-hook-goal-idle".command = "harness-hook-goal-idle";
        "harness-hook-goal-compact".command = "harness-hook-goal-compact";
        "harness-hook-goal-tools".command = "harness-hook-goal-tools";
        "harness-hook-goal-arm".command = "harness-hook-goal-arm";
        "harness-hook-goal-tokens".command = "harness-hook-goal-tokens";
        # Linters (no-find-grep, simple-english).
        "harness-hook-no-find-grep".command = "harness-hook-no-find-grep";
        "harness-hook-simple-english".command = "harness-hook-simple-english";
      };

      # One [hooks.pipeline."<window>"] entry per window. Steps
      # fire in list order; a later step may veto an earlier
      # one.
      pipeline = {
        "exhausted.handle".steps = [ "harness-hook-compact" ];
        "overflow.resolve".steps = [ "harness-hook-compact" ];
        "run.idle".steps = [
          "harness-hook-goal-idle"
          "harness-hook-simple-english"
        ];
        "compact.before".steps = [ "harness-hook-goal-compact" ];
        "tool.before".steps = [
          "harness-hook-goal-tools"
          "harness-hook-no-find-grep"
          "harness-hook-no-long-sleep"
          "harness-hook-simple-english"
        ];
        "model.before".steps = [
          "harness-hook-goal-arm"
          "harness-hook-simple-english"
        ];
        "model.after".steps = [ "harness-hook-goal-tokens" ];
      };
    };

    # [loop]
    loop = {
      arg_style = "append_session";
      args = [ "run" ];
      command = "rushi";
    };

    # [system_prompt] (the consumer's own prompt file)
    system_prompt = {
      text = builtins.readFile ./system-prompt.txt;
    };

    # [tui]
    tui = {
      clipboard = "unnamed";
      tool_display = {
        anim_ms = 400;
        bash_collapsed_lines = 5;
        diff_collapsed_lines = 12;
        expand_mode = "click";
        highlight_engine = "tree-sitter";
        preset = "opencode";
      };
    };
  };
}
