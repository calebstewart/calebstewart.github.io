# calebstewart.github.io

Landing page for my GitHub account — an intro and a menu of links to the other
sites and projects I run. Built with [Zola](https://www.getzola.org/), pinned
through a Nix flake, and deployed to GitHub Pages by Actions.

## Layout

| Path                          | What it is                                                     |
| ----------------------------- | -------------------------------------------------------------- |
| `content/_index.md`           | Landing page prose. Plain markdown.                             |
| `content/resume/`             | Résumé content — see [Résumé](#résumé) below.                    |
| `data/*.yaml`                 | Certifications and education (pure data, no prose).             |
| `config.toml`                 | Site metadata, the `[extra]` link menus, and `[extra.resume]`.  |
| `templates/`                  | `index.html` (landing) and `resume.html` (résumé).              |
| `resume.typ`                  | Typst source for the PDF résumé.                                |
| `static/`                     | `style.css`, `favicon.svg` — copied to the site root verbatim.  |
| `flake.nix`                   | Dev shell, build derivations, and the consistency check.        |
| `.github/workflows/pages.yml` | Builds via `nix build` and deploys.                             |

## Editing

Prose lives in `content/_index.md` and is rendered into the `.intro` section.
Links live in `config.toml` under `[[extra.projects]]` (the "Elsewhere" menu)
and `[[extra.social]]` (the footer row). Adding an entry is three lines of TOML;
no template change needed.

The header photo is `extra.avatar` in `config.toml`, pointed at
`avatars.githubusercontent.com` so it tracks the GitHub account avatar with
nothing to re-upload here. Note the path takes the **numeric** user id
(`7529189`), not the username. `?s=176` is deliberately 2x the 88px display size
so it stays sharp on HiDPI displays.

The tab icon is `static/favicon.svg` — a self-contained "cs" monogram, served
from this repo rather than fetched from GitHub. It carries its own
`prefers-color-scheme` rule so it inverts in dark mode. Pointing `rel=icon` at
the remote avatar instead does work, but GitHub serves avatars with
`max-age=300`, so it means a third-party refetch every five minutes for no real
gain.

One caveat: `.tagline` is sized in `static/style.css` to clear the avatar
without wrapping. Lengthen the tagline and it will wrap awkwardly beside the
photo — check it after editing.

## Résumé

One source, two outputs. `content/resume/` holds a markdown file per role and
per project — TOML frontmatter for the metadata, the body for the prose. The web
page and the PDF read those same files; there is no generated intermediate and
nothing to keep in sync.

```
content/resume/_index.md              summary paragraph
content/resume/experience/*.md        one file per role
content/resume/projects/*.md          one file per project
data/certifications.yaml              pure data, no prose
data/education.yaml                   pure data, no prose
```

Adding a role means creating the file **and** adding its filename to the
relevant list in `config.toml` under `[extra.resume]`. Those lists are the
single source of truth for both membership and display order — the web template
and `resume.typ` each walk them in order, so the page and the PDF cannot
disagree. Reorder there to reorder both.

The explicit list exists because Typst has no directory enumeration, which is
deliberate on Typst's part: it's what lets compilation stay hermetic. Forgetting
to add a file is the one failure mode that creates, so `nix flake check` fails
if a file exists on disk but isn't listed. CI runs that check before building.

The role pages set `render = false`, so they don't emit standalone URLs; they
exist only to be pulled into the résumé page and the PDF.

### Why Typst rather than LaTeX

The previous version of this résumé lived in the `calebstew.art` repo and used
Hugo templates to *generate* a `.tex` file. Go templates and LaTeX both claim
`{}`, so every brace had to be laundered through a string literal — the old
template was full of `{{"{"}}`. Typst loads structured data natively, so nothing
generates Typst source: `resume.typ` is a real document that reads `config.toml`
and the content files itself. Typst is also ~103 MiB of closure and compiles in
under a tenth of a second, against ~0.6 GiB for even a small TeXLive, which is
what makes it reasonable to build the résumé from the same repo as the website.

Markdown bodies are rendered by `cmarker`, pulled from nixpkgs rather than
Typst's own package fetcher so the build stays hermetic and works offline in CI.

```console
nix build .#resume    # just the PDF, at ./result/resume.pdf
nix build .#site      # the whole site, with the PDF at /resume.pdf
```

## Local preview

```console
nix develop        # or `direnv allow` — .envrc is already set up
zola serve         # live-reloading preview at http://127.0.0.1:1111
```

The dev shell also provides `typst` with `cmarker` and the Roboto font path
already set, so `typst compile resume.typ` works by hand for quick iteration on
the PDF layout.

To build exactly what CI builds:

```console
nix flake check    # résumé manifest consistency
nix build .#site   # output lands in ./result
```

CI runs that same check and build, so what you see locally is what deploys.

Note that `zola serve` does not recover from an error in a file you then delete —
it keeps serving the stale error. Restart it if that happens.

## Link strategy

Every internal link is **root-relative** (`/stewos/`, `/style.css`) rather than
absolute. That means the whole site works unchanged whether it's being served
from `calebstewart.github.io` or `calebstew.art`, which matters during the
domain migration below. Only `<link rel=canonical>` and the OpenGraph URLs are
absolute, which is what those tags are for — they're driven by `base_url` in
`config.toml`.

## GitHub configuration

### 1. Enable Pages with the Actions source

Settings → Pages → **Build and deployment** → Source: **GitHub Actions**.
Without this, the workflow's deploy step fails. Pushing to `main` then builds
and publishes to `https://calebstewart.github.io`.

### 2. Moving the `calebstew.art` custom domain here

GitHub allows a custom domain to be attached to exactly one repository, so the
order matters:

1. In the **`calebstewart/calebstew.art`** repo: Settings → Pages → remove the
   custom domain. (That repo's site then falls back to
   `calebstewart.github.io/calebstew.art`, and will move to
   `calebstew.art/calebstew.art` once step 2 completes. Archive or delete it if
   it's fully superseded by this one.)
2. In **this** repo: Settings → Pages → set the custom domain to
   `calebstew.art`, then tick **Enforce HTTPS** once the certificate is issued
   (can take a few minutes to an hour).
3. Account level: Settings → Pages → **Verify domain** for `calebstew.art`.
   Verification is what stops another GitHub account from claiming the domain,
   which is worth doing given it sits unattached between steps 1 and 2.

**DNS needs no changes.** The apex `A`/`AAAA` records already point at GitHub's
Pages IPs; GitHub routes by the domain configured on the repo, not by DNS.

### 3. The knock-on effect on other repos

Once `calebstew.art` is the user-site domain, every *other* repo in the account
that publishes a Pages site and has no custom domain of its own is served from
`calebstew.art/{repo}` instead of `calebstewart.github.io/{repo}`. That's the
intended outcome here, and it's what makes the root-relative `/stewos/` and
`/recipes/` links in `config.toml` resolve.

Repos with their own custom domain are unaffected — `python-sigma` keeps
serving at `sigma.calebstew.art`.

### 4. `CNAME` file

Not committed, deliberately. With the Actions-based deployment the domain set in
repo settings is authoritative, and committing a `CNAME` for a domain that's
still attached to another repo would only cause a failed deploy. If you'd rather
have it in version control after the migration, drop a `CNAME` file containing
`calebstew.art` into `static/`.

## Outstanding

- `/recipes/` in `config.toml` assumes that repo will have Pages enabled. It has
  no Pages site yet — enable it, or drop the entry, before the link resolves.
- The `calebstewart/resume` repo is stale and unrelated to this résumé; the live
  one used to be built in `calebstew.art`. Once the domain move is done, both of
  those repos are superseded by this one and can be archived.
