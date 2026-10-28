{
  description = "rushi configured declaratively as a consumer of rushi-config.";

  # This repo is the consumer side of the rushi-config
  # deployment layer (the my-nix-nvim vs nixvim shape): it
  # owns the ext set and the config, the flake only assembles
  # them through rushi-config's builder.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # The deployment layer (the kernel + TUI + the builder).
    # Pinned by the lock; bump with `nix flake update
    # rushi-config`.
    rushi-config = {
      url = "github:TonyWu20/rushi-config";
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
    nixpkgs, rushi-config,
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
    rushiModule = import ./rushi/default.nix;

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
          modules = [ rushiModule ];
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
  in
  {
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
