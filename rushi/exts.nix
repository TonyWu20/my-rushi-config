# rushi/exts.nix — the consumer ext set, as data.
#
# The raw exts table: per-package selection out of the ext
# flake inputs the flake holds. Per-package (not the
# whole-flake rushiExt fold) so the `goal` loop tool stays
# out: the agent does not need to see it (the 2026-10-12
# decision, rushi-config docs/decisions.md). The
# terminal-browser ext is not enabled in this build.
#
# The kernel's build-time drift guard checks every
# [hooks] def against a bundled binary, so each hook def in
# rushi/default.nix pairs with one extHooks row here.

{
  # The target system.
  system,
  # The ext flake inputs (the flake's named inputs, stated
  # explicitly at the boundary).
  rushiGoalMode,
  rushiWebAccess,
  rushiNoFindGrep,
  rushiMineruPdf,
  rushiImageRead,
  rushiSimpleEnglish,
  rushiStatusline,
  rushiTuiMermaidExt,
}:
{
  # External tool packages. One row per ext tool. The
  # producer's meta.rushi.entry (kernel issue #13) supplies
  # the tools/<entry> path the generated config carries.
  extTools = [
    rushiGoalMode.packages.${system}."goal-blocked"
    rushiGoalMode.packages.${system}."goal-complete"
    rushiWebAccess.packages.${system}."web-fetch"
    rushiWebAccess.packages.${system}."web-search"
    rushiMineruPdf.packages.${system}.mineru
    rushiImageRead.packages.${system}.img
  ];

  # External UI extension packages. The producer's
  # meta.rushi.ext supplies the [ui_extensions] entry name at
  # eval time.
  extUi = [
    rushiGoalMode.packages.${system}."goal-ext"
    rushiSimpleEnglish.packages.${system}."simple-english-ext"
    rushiStatusline.packages.${system}.statusline
    rushiTuiMermaidExt.packages.${system}."mermaid-ext"
  ];

  # External hook packages, bundled into the package's hooks/
  # dir. Each producer's meta.rushi.bin names the bundled
  # binary.
  extHooks = [
    rushiGoalMode.packages.${system}."hook-goal-idle"
    rushiGoalMode.packages.${system}."hook-goal-compact"
    rushiGoalMode.packages.${system}."hook-goal-tools"
    rushiGoalMode.packages.${system}."hook-goal-arm"
    rushiGoalMode.packages.${system}."hook-goal-tokens"
    rushiNoFindGrep.packages.${system}."hook-no-find-grep"
    rushiSimpleEnglish.packages.${system}."hook-simple-english"
  ];
}
