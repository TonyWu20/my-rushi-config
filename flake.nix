{
  description = "rushi configured declaratively as a consumer of rushi-config.";

  # This repo is the consumer side of the rushi-config
  # deployment layer (the my-nix-nvim vs nixvim shape): it
  # owns the ext set, the config, and the version pins
  # (kernel + TUI), the flake only assembles them through
  # rushi-config's builder.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The deployment layer (the builder). Pinned by the
    # lock; bump with `nix flake update rushi-config`. The
    # bump is for the builder logic, not the kernel: the
    # version pins are this repo's own inputs (below),
    # passed to the builder.
    rushi-config = {
      url = "github:TonyWu20/rushi-config";
    };

    # The version pins (consumer data, the exts precedent):
    # the kernel flake (lib.mkRushi + the raw kernel package)
    # and the TUI flake (the raw TUI package). Bump with
    # `nix flake update rushi-kernel` / `nix flake update
    # rushi-tui`: the kernel update never re-locks
    # rushi-config. Each follows this flake's shared
    # nixpkgs + fenix, so the whole graph shares one
    # toolchain.
    rushi-kernel = {
      url = "github:TonyWu20/rushi";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    rushi-tui = {
      url = "github:TonyWu20/rushi-tui";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
      # The TUI flake's rushi-config input (its devshell
      # launcher) aliases this repo's own pin, so the
      # graph keeps one rushi-config source:
      inputs.rushi-config.follows = "rushi-config";
    };

    # The exts, this repo's own inputs. Each ext repo is
    # self-contained (it tracks only nixpkgs/fenix, not the
    # kernel), so a kernel update is never a re-lock of the
    # exts. Each follows this flake's shared nixpkgs + fenix,
    # so the whole build graph shares one toolchain.
    rushi-goal-mode = {
      url = "github:TonyWu20/rushi-goal-mode";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    rushi-obscura-web-access = {
      url = "github:TonyWu20/rushi-obscura-web-access";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    no-find-grep = {
      url = "github:TonyWu20/no-find-grep-rushi";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    rushi-mineru-pdf = {
      url = "github:TonyWu20/rushi-mineru-pdf";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    rushi-image-read = {
      url = "github:TonyWu20/rushi-image-read";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    rushi-simple-english = {
      url = "github:TonyWu20/rushi-simple-english";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    rushi-statusline = {
      url = "github:TonyWu20/rushi-statusline";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
    rushi-tui-mermaid-ext = {
      url = "github:TonyWu20/rushi-tui-mermaid-ext";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.fenix.follows = "fenix";
    };
  };

  outputs = {
    nixpkgs, rushi-config, rushi-kernel, rushi-tui,
    rushi-goal-mode, rushi-obscura-web-access, no-find-grep,
    rushi-mineru-pdf, rushi-image-read, rushi-simple-english,
    rushi-statusline, rushi-tui-mermaid-ext,
    ...
  }:
  let
    systems = [ "x86_64-linux" "aarch64-darwin" ];
    lib = nixpkgs.lib;

    # The declarative rushi config (the rushi.* options: the
    # model, limits, hook pipeline, loop, prompt, TUI).
    # The declarative config module, per system: the rushi.*
    # options, the TUI extension set (rushi.external_ui_
    # extensions), and the personal config tree.
    rushiModuleFor =
      system:
      import ./rushi/default.nix {
        inherit system;
        rushiGoalMode = rushi-goal-mode;
        rushiSimpleEnglish = rushi-simple-english;
        rushiStatusline = rushi-statusline;
        rushiTuiMermaidExt = rushi-tui-mermaid-ext;
      };

    # The consumer ext set (the raw exts table, per-package
    # selection; the data file takes the ext flake inputs
    # explicitly at the boundary).
    extsFor =
      system:
      import ./rushi/exts.nix {
        inherit system;
        rushiGoalMode = rushi-goal-mode;
        rushiWebAccess = rushi-obscura-web-access;
        rushiNoFindGrep = no-find-grep;
        rushiMineruPdf = rushi-mineru-pdf;
        rushiImageRead = rushi-image-read;
        rushiSimpleEnglish = rushi-simple-english;
        rushiStatusline = rushi-statusline;
        rushiTuiMermaidExt = rushi-tui-mermaid-ext;
      };

    # The consumer rushi build: the builder (the configured
    # kernel + the TUI merge, with the ext set and the config
    # module), plus the headless goal seeder merged into
    # bin/ so it resolves this package's root config.toml
    # side by side.
    rushiFor =
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        base = rushi-config.lib.mkRushiFull {
          inherit system;
          exts = extsFor system;
          modules = [ (rushiModuleFor system) ];
          # The version pins: this repo's own lock pins.
          kernel = rushi-kernel;
          tui = rushi-tui;
        };
        seeder = rushi-goal-mode.packages.${system}."rushi-goal";
      in
      pkgs.stdenv.mkDerivation {
        pname = "rushi-custom";
        version = "0.1";
        nativeBuildInputs = [ base seeder ];
        unpackPhase = "true";
        installPhase = ''
          cp -a ${base}/. $out/
          chmod -R u+w $out
          cp ${seeder}/bin/rushi-goal $out/bin/rushi-goal
          chmod +x $out/bin/rushi-goal
        '';
      };

    # The home-manager entrypoint (the my-nix-nvim shape:
    # nixvim exposes both spellings). The consumer imports
    # this module into their home-manager evaluation; it
    # turns on programs.rushi (the kernel's home-manager
    # module, re-exposed by rushi-config) and feeds it the
    # consumer build — the same package as
    # packages.<system>.rushi, for the consumer's evaluation
    # system.
    homeModule =
    { config, lib, pkgs, ... }:
    let
      system = pkgs.stdenv.hostPlatform.system;
    in
    {
      imports = [ rushi-config.homeManagerModules.rushi ];
      programs.rushi = {
        enable = true;
        package = rushiFor system;
      };
    };
  in
  {
    # Home-manager entrypoints (both spellings, the my-nix-nvim
    # shape). The consumer imports this module; it turns on
    # programs.rushi with the consumer build as the package.
    homeModules = {
      default = homeModule;
    };
    homeManagerModules = {
      default = homeModule;
    };

    # The consumer rushi build: `nix build .#` or .#rushi.
    # The package carries bin/ (rushi, rushi-tui, rushi-goal,
    # the hook bins), tools/, ui_extensions/, hooks/,
    # config.toml.
    packages = lib.genAttrs systems (
      system:
      {
        default = rushiFor system;
        rushi = rushiFor system;
      }
    );

    # A dev shell with the deployment on PATH.
    devShells = lib.genAttrs systems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        rushi = rushiFor system;
      in
      {
        default = pkgs.mkShell {
          packages = [ rushi ];
        };
      }
    );
  };
}
