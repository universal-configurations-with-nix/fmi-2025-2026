{
  description = "Universal configurations with Nix, FMI, 2025/2026";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ withSystem, flake-parts-lib, ... }: {
      systems = [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem = { lib, pkgs, system, ... }:
        {
          devShells.default = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              just
              pandoc
              cm_unicode
              (texlive.combine {
                inherit (texlive)
                  scheme-small
                  babel-bulgarian
                  cyrillic
                  ;
              })
            ];
          };
        };
    });
}
