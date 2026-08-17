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
      packages = forAllSystems (
        pkgs:
        let
          src = builtins.path {
            path = ./.;
            name = "site-source";
            filter =
              path: type:
              let
                base = baseNameOf path;
              in
              # `static/resume.pdf` is a local-preview artifact (see .gitignore).
              # Excluded so a stale local build can't leak into the real output,
              # which always takes the PDF from the `resume` derivation.
              !(builtins.elem base [
                ".git"
                ".github"
                "public"
                "result"
                "flake.nix"
                "flake.lock"
              ])
              && !(type == "regular" && baseNameOf (dirOf path) == "static" && base == "resume.pdf");
          };

          # cmarker renders the markdown bodies of the résumé content files.
          # Pulling it from nixpkgs rather than Typst's own package fetcher is
          # what keeps the build hermetic and offline-capable in CI.
          typst = pkgs.typst.withPackages (ps: [ ps.cmarker ]);
        in
        rec {
          default = site;

          # The PDF résumé, built from the same content/ files the site renders.
          resume = pkgs.stdenvNoCC.mkDerivation {
            pname = "calebstew-art-resume";
            version = "0.1.0";
            inherit src;

            nativeBuildInputs = [ typst ];

            buildPhase = ''
              runHook preBuild
              typst compile \
                --font-path ${pkgs.roboto}/share/fonts \
                --root . \
                resume.typ resume.pdf
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              install -Dm644 resume.pdf $out/resume.pdf
              runHook postInstall
            '';
          };

          # The website, with the PDF dropped in at the root so the résumé page
          # can link /resume.pdf.
          site = pkgs.stdenvNoCC.mkDerivation {
            pname = "calebstew-art";
            version = "0.1.0";
            inherit src;

            nativeBuildInputs = [ pkgs.zola ];

            buildPhase = ''
              runHook preBuild
              zola build --output-dir ./public
              cp ${resume}/resume.pdf ./public/resume.pdf
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              cp -r ./public $out
              runHook postInstall
            '';
          };
        }
      );

      # Typst cannot enumerate directories, so config.toml carries an explicit
      # list of résumé content files while Zola discovers them from the
      # filesystem. That's the one place the two can silently diverge: a new
      # role would appear on the site but vanish from the PDF. This catches it.
      checks = forAllSystems (pkgs: {
        resume-manifest = pkgs.runCommand "check-resume-manifest" { } ''
          cd ${./.}
          status=0
          for kind in experience projects; do
            on_disk=$(${pkgs.findutils}/bin/find "content/resume/$kind" -name '*.md' \
              ! -name '_index.md' -printf '%f\n' | sort)
            in_config=$(${pkgs.gnused}/bin/sed -n "/^$kind = \[/,/^]/p" config.toml \
              | ${pkgs.gnugrep}/bin/grep -o '"[^"]*\.md"' | tr -d '"' | sort)
            if [ "$on_disk" != "$in_config" ]; then
              echo "config.toml [extra.resume].$kind does not match content/resume/$kind/:"
              ${pkgs.diffutils}/bin/diff <(echo "$in_config") <(echo "$on_disk") \
                --label config.toml --label on-disk -u || true
              status=1
            fi
          done
          [ $status -eq 0 ] && touch $out
          exit $status
        '';
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.zola
            (pkgs.typst.withPackages (ps: [ ps.cmarker ]))
          ];

          # Typst needs to be told where Roboto lives; the flake's build does
          # this with --font-path, so mirror it here for `typst compile` by hand.
          TYPST_FONT_PATHS = "${pkgs.roboto}/share/fonts";

          shellHook = ''
            # `zola serve` only knows about static/, so the PDF has to land
            # there for /resume.pdf to resolve during local preview.
            resume-pdf() {
              typst compile resume.typ static/resume.pdf && echo "-> static/resume.pdf"
            }

            echo "zola $(zola --version | cut -d' ' -f2) — 'zola serve' to preview at http://127.0.0.1:1111"
            echo "typst $(typst --version | cut -d' ' -f2) — 'resume-pdf' to build the PDF for local preview"
          '';
        };
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
