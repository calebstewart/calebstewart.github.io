{
  description = "Personal landing page for calebstew.art";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        default = site;

        site = pkgs.stdenvNoCC.mkDerivation {
          pname = "calebstew-art";
          version = "0.1.0";

          src = builtins.path {
            path = ./.;
            name = "site-source";
            filter =
              path: type:
              let
                base = baseNameOf path;
              in
              !(builtins.elem base [
                ".git"
                ".github"
                "public"
                "result"
                "flake.nix"
                "flake.lock"
              ]);
          };

          nativeBuildInputs = [ pkgs.zola ];

          buildPhase = ''
            runHook preBuild
            zola build --output-dir ./public
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            cp -r ./public $out
            runHook postInstall
          '';
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.zola ];

          shellHook = ''
            echo "zola $(zola --version | cut -d' ' -f2) — 'zola serve' to preview at http://127.0.0.1:1111"
          '';
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
