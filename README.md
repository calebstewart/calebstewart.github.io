# calebstewart.github.io

Landing page for my GitHub account — an intro and a menu of links to the other
sites and projects I run. Built with [Zola](https://www.getzola.org/), pinned
through a Nix flake, and deployed to GitHub Pages by Actions.

## Layout

| Path                        | What it is                                                    |
| --------------------------- | ------------------------------------------------------------- |
| `content/_index.md`         | The prose. Plain markdown — this is the file you'll edit most. |
| `config.toml`               | Site metadata and the `[extra]` link menus.                    |
| `templates/index.html`      | The single page template.                                      |
| `static/`                   | `style.css`, `favicon.svg` — copied to the site root verbatim. |
| `flake.nix`                 | Dev shell and the build derivation.                            |
| `.github/workflows/pages.yml` | Builds via `nix build` and deploys.                          |

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

## Local preview

```console
nix develop        # or `direnv allow` — .envrc is already set up
zola serve         # live-reloading preview at http://127.0.0.1:1111
```

To build exactly what CI builds:

```console
nix build .#site   # output lands in ./result
```

CI runs that same `nix build`, so what you see locally is what deploys.

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

- `/resume/` and `/recipes/` in `config.toml` assume those repos will have Pages
  enabled. `resume` is currently private and `recipes` has no Pages site yet —
  enable Pages on each, or drop the entry, before those links resolve.
