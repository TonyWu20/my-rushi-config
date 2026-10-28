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
                       the 8 ext flake inputs)
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

- `rushi-config` is a plain github input: the deployment
  layer (the kernel + the TUI + the builder). It holds no
  ext flake inputs, so bumping it is the only rushi-side
  re-lock.
- The 8 ext flake inputs are this repo's own inputs
  (consumer data). Each ext repo is self-contained — it
  tracks only nixpkgs/fenix, never the kernel — so a kernel
  update is never a re-lock of the exts. Each follows this
  flake's shared nixpkgs + fenix, so the whole graph builds
  under one toolchain.
- `packages.rushi` = `mkRushiFull { exts = <the raw table>;
  modules = [ ./rushi/default.nix ] }`, with the headless
  goal seeder merged into `bin/` so it resolves the package
  root config side by side.
- The ext set is the **raw table** (per-package), not the
  whole-flake `rushiExt` fold: the `goal` loop tool is
  deliberately out (the agent does not need to see it). The
  terminal-browser ext is not enabled.

## Usage

```
nix build  .#          # the deployment package
nix develop .#         # dev shell: rushi, rushi-tui, rushi-goal on PATH
```

## Bumping the inputs

```
nix flake update                    # everything
nix flake update rushi-config       # just the deployment layer
nix flake update rushi-goal-mode   # just one ext
```

Every ext and hook the [hooks] pipeline names must be
bundled by the exts table: the kernel's build-time drift
guard fails the build on an unmatched bare command, so a
typo or a renamed ext is loud, not silent.
