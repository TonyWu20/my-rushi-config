# my-rushi-config

A declarative rushi deployment, managed as a consumer of
[rushi-config](https://github.com/TonyWu20/rushi-config) —
the rushi analog of the my-nix-nvim vs nixvim shape: the
consumer repo owns the ext set and the config; the flake
only assembles them through the deployment layer's
builder (`rushi-config.lib.mkRushiFull`).

## Repo layout

```
flake.nix              Flake entry point: inputs and outputs
flake.lock             Pinned inputs (nixpkgs, fenix, rushi-config,
                       the 2 version-pin flake inputs, the 8 ext
                       flake inputs)
rushi/
  default.nix          The declarative module: the rushi.* options
                       (model, limits, the [hooks] pipeline, loop,
                       system prompt, TUI, the native tool list)
  exts.nix             The ext set, as data: the raw exts table
                       (per-package selection out of the ext flake
                       inputs)
  system-prompt.txt    The personal system prompt
```

## How the flake is wired

- `rushi-config` is a plain github input: the builder.
  Bumping it is for the builder logic (a kernel Nix API
  change), not a kernel release. It holds no ext flake
  inputs.
- The version pins (`rushi-kernel`, `rushi-tui`) are this
  repo's own github inputs (consumer data, the exts
  precedent), passed to the builder. A kernel update is a
  re-lock of this repo, never of rushi-config. Each follows
  this flake's shared nixpkgs + fenix, so the whole graph
  builds under one toolchain.
- The 8 ext flake inputs are this repo's own inputs
  (consumer data). Each ext repo is self-contained — it
  tracks only nixpkgs/fenix, never the kernel — so a kernel
  update is never a re-lock of the exts.
- `packages.rushi` = `mkRushiFull { kernel = rushi-kernel;
  tui = rushi-tui; exts = <the raw table>;
  modules = [ ./rushi/default.nix ] }`, with the headless
  goal seeder merged into `bin/` so it resolves the package
  root config side by side.
- `homeManagerModules.default` (also `homeModules.default`,
  the my-nix-nvim shape) is the home-manager entrypoint:
  the consumer imports it into their home-manager
  evaluation; it turns on `programs.rushi` (the kernel's
  home-manager module) with this same consumer package, so
  the deployment lands in the home profile's `bin/`.
- The ext set is the **raw table** (per-package), not the
  whole-flake `rushiExt` fold: the `goal` loop tool is
  deliberately out (the agent does not need to see it). The
  terminal-browser ext is not enabled. The table carries
  the tool and hook packages; the TUI extension set (goal,
  simple-english, statusline, mermaid) is declared by the
  config module (`rushi.external_ui_extensions`) — the
  single declarative place for the TUI exts.

## Usage

```
nix build  .#          # the deployment package
nix develop .#         # dev shell: rushi, rushi-tui, rushi-goal on PATH
```

Or as a home-manager module (in the consumer's home
evaluation):

```nix
imports = [ mrc.homeManagerModules.default ];
# programs.rushi is enabled by the module itself; the
# deployment's rushi, rushi-tui, rushi-goal land in the
# profile's bin/.
```

## Bumping the inputs

```
nix flake update                     # everything
nix flake update rushi-kernel        # the kernel pin only
nix flake update rushi-tui           # the TUI pin only
nix flake update rushi-config        # the builder only
nix flake update rushi-goal-mode     # just one ext
```

`nix flake update rushi-kernel` re-locks only the kernel
node: the rushi-config node stays put. The rushi-config
bump is for the builder logic, not a kernel release.

Every ext and hook the [hooks] pipeline names must be
bundled by the exts table: the kernel's build-time drift
guard fails the build on an unmatched bare command, so a
typo or a renamed ext is loud, not silent.
