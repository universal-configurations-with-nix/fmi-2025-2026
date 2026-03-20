{
  description = "UCWN Typst presentations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    typix = {
      url = "github:loqusion/typix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({
      systems = import inputs.systems;
      perSystem =
        {
          lib,
          pkgs,
          system,
          ...
        }:
        let
          typixLib = inputs.typix.lib.${system};
          inherit (lib.strings) escapeShellArg;
          repoRoot = toString ./.;

          commonFontPaths = [
            "${pkgs.maple-mono.Normal-OTF}/share/fonts/opentype"
            "${pkgs.fira-sans}/share/fonts/opentype"
            "${pkgs.jetbrains-mono}/share/fonts/truetype"
          ];

          commonTypstPackages = [
            {
              name = "metropolyst";
              version = "0.1.0";
              hash = "sha256-+SF1zqADvSTpsyrEQWgiNGhF83JTOeLZglApGJlaEtM=";
            }
            {
              name = "touying";
              version = "0.6.1";
              hash = "sha256-bTDc32MU4GPbUbW5p4cRSxsl9ODR6qXinvQGeHu2psU=";
            }
          ];

          mkTypstPackagesDrv =
            name: entries:
            let
              linkFarmEntries = lib.foldl (
                set:
                {
                  name,
                  version,
                  namespace,
                  input,
                }:
                set
                // {
                  "${namespace}/${name}/${version}" = input;
                }
              ) { } entries;
            in
            pkgs.linkFarm name linkFarmEntries;

          localTypstPackages = mkTypstPackagesDrv "local-typst-packages" [
            {
              name = "ucwn-common";
              version = "0.1.0";
              namespace = "local";
              input = ./typst-packages/ucwn-common;
            }
          ];

          deckNames = lib.pipe ./decks [
            builtins.readDir
            (lib.filterAttrs (_: type: type == "directory"))
            builtins.attrNames
          ];

          mkDeck =
            name:
            let
              deckDir = ./decks/${name};
              deckModule = import (deckDir + "/deck.nix");
              deckArgs = if builtins.isFunction deckModule then deckModule { inherit pkgs lib; } else deckModule;

              src = lib.sources.cleanSourceWith {
                src = ./.;
                filter =
                  path: _type:
                  let
                    pathString = toString path;
                    rootString = toString ./.;
                    relativePath =
                      if pathString == rootString then "" else lib.strings.removePrefix "${rootString}/" pathString;

                    inDecks = relativePath == "decks" || lib.hasPrefix "decks/" relativePath;
                    inTypstPackages = relativePath == "typst-packages" || lib.hasPrefix "typst-packages/" relativePath;

                    temporaryPdf = lib.hasPrefix "decks/" relativePath && lib.hasSuffix ".pdf" relativePath;
                    buildArtifact = lib.hasPrefix "build/" relativePath;
                  in
                  (relativePath == "" || inDecks || inTypstPackages) && !temporaryPdf && !buildArtifact;
              };

              fontPaths = commonFontPaths ++ (deckArgs.fontPaths or [ ]);
              virtualPaths = deckArgs.virtualPaths or [ ];
              unstable_typstPackages = commonTypstPackages ++ (deckArgs.unstable_typstPackages or [ ]);

              typstSource = "decks/${name}/${deckArgs.typstSource}";
              typstOutput = "decks/${name}/${lib.strings.removeSuffix ".typ" deckArgs.typstSource}.pdf";

              commonArgs = {
                inherit
                  src
                  typstSource
                  typstOutput
                  fontPaths
                  virtualPaths
                  unstable_typstPackages
                  ;
                TYPST_PACKAGE_PATH = localTypstPackages;
              };
              mkVariant =
                {
                  suffix ? "",
                  typstOpts ? { },
                }:
                let
                  variantArgs = commonArgs // lib.optionalAttrs (typstOpts != { }) { inherit typstOpts; };
                  watchArgs = builtins.removeAttrs variantArgs [
                    "TYPST_PACKAGE_PATH"
                    "src"
                    "unstable_typstPackages"
                  ];
                  variantScriptSuffix = if suffix == "" then "" else "-${suffix}";
                in
                {
                  package = (typixLib.buildTypstProject variantArgs).overrideAttrs {
                    name = if suffix == "" then "${name}.pdf" else "${name}-${suffix}.pdf";
                    passthru = {
                      build = typixLib.buildTypstProjectLocal (
                        variantArgs
                        // {
                          scriptName = "build-${name}${variantScriptSuffix}";
                        }
                      );
                      watch = typixLib.watchTypstProject (
                        watchArgs
                        // {
                          scriptName = "watch-${name}${variantScriptSuffix}";
                          typstWatchCommand = "TYPST_PACKAGE_PATH=${escapeShellArg localTypstPackages} typst watch";
                        }
                      );
                      inherit fontPaths virtualPaths;
                    };
                  };
                  check = typixLib.buildTypstProject variantArgs;
                };
            in
            {
              handout = mkVariant { };
              presentable = mkVariant {
                suffix = "presentable";
                typstOpts.input = [ "ucwn_mode=presentable" ];
              };
            };

          decks = lib.mapAttrs (_: mkDeck) (lib.genAttrs deckNames lib.id);
          allHandoutPackages = lib.mapAttrsToList (_: p: p.handout.package) decks;
          allPresentablePackages = lib.mapAttrsToList (_: p: p.presentable.package) decks;

          mkWatchScript =
            {
              name,
              mode,
              outputDir,
            }:
            pkgs.writeShellApplication {
              inherit name;
              runtimeInputs = [
                pkgs.coreutils
                pkgs.findutils
                pkgs.typst
              ];
              text = ''
                set -eu

                if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
                  echo "usage: ${name} <deck-prefix> [output.pdf]" >&2
                  exit 1
                fi

                selector="$1"
                output="''${2:-}"
                repo_root=${escapeShellArg repoRoot}

                deck_path="$(find "$repo_root/decks" -maxdepth 1 -mindepth 1 -type d -name "$selector*" | sort | head -n 1)"
                if [ -z "$deck_path" ]; then
                  echo "No deck found for prefix $selector" >&2
                  exit 1
                fi

                deck_name="''${deck_path##*/}"
                if [ -z "$output" ]; then
                  output="$repo_root/${outputDir}/$deck_name.pdf"
                fi

                mkdir -p "$(dirname "$output")"

                exec typst watch \
                  --root "$repo_root" \
                  ${lib.optionalString (mode == "presentable") "--input ucwn_mode=presentable \\"}
                  "$repo_root/decks/$deck_name/main.typ" \
                  "$output"
              '';
            };

          watchSlide = mkWatchScript {
            name = "watch-slide";
            mode = "handout";
            outputDir = "build/slides";
          };

          watchPresentableSlide = mkWatchScript {
            name = "watch-presentable-slide";
            mode = "presentable";
            outputDir = "build/presentable";
          };
        in
        lib.mkMerge (
          (lib.mapAttrsToList (name: deck: {
            packages = {
              ${name} = deck.handout.package;
              "${name}-presentable" = deck.presentable.package;
            };
            checks = {
              ${name} = deck.handout.check;
              "${name}-presentable" = deck.presentable.check;
            };
          }) decks)
          ++ [
            {
              packages.default = lib.pipe decks [
                (lib.mapAttrsToList (
                  name: deck: {
                    name = "${name}.pdf";
                    path = deck.handout.package;
                  }
                ))
                (pkgs.linkFarm "ucwn-typst-decks")
              ];

              packages.presentable = lib.pipe decks [
                (lib.mapAttrsToList (
                  name: deck: {
                    name = "${name}.pdf";
                    path = deck.presentable.package;
                  }
                ))
                (pkgs.linkFarm "ucwn-typst-decks-presentable")
              ];

              devShells.default = typixLib.devShell {
                TYPST_PACKAGE_PATH = localTypstPackages;
                fontPaths = lib.concatMap (p: p.fontPaths) allHandoutPackages;
                virtualPaths = lib.concatMap (p: p.virtualPaths) allHandoutPackages;
                packages = [
                  pkgs.just
                  pkgs.pandoc
                  pkgs.python3
                  pkgs.tinymist
                  pkgs.typstyle
                  pkgs.websocat
                  watchSlide
                  watchPresentableSlide
                ];
              };
            }
          ]
        );
    });
}
