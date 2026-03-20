# UCWN Typst

Typst-first presentation workflow for the UCWN/FMI lectures.

Canonical slide sources now live under `decks/` and build through Typst, Touying, Metropolyst, Typix, and Nix. Shared Typst glue is provided as a local package under `typst-packages/`. The older markdown/pandoc sources are kept under `src/` as legacy reference material.

There are two output modes:

- handout: the default build, with overlay steps collapsed
- presentable: incremental bullet reveals, similar to the old `-presentable` beamer targets

Useful commands:

- `nix build` builds the full PDF set
- `nix build .#presentable` builds the full presentable PDF set
- `nix build .#05-derivation-and-mkDerivation` builds one deck
- `nix build .#05-derivation-and-mkDerivation-presentable` builds one presentable deck
- `just build-slide 05` resolves a numeric prefix and builds that deck
- `just build-presentable-slide 05` resolves a numeric prefix and builds that deck in presentable mode
- `just watch-slide 05` runs `typst watch` into `build/slides/`
- `just watch-presentable-slide 05` runs `typst watch` into `build/presentable/`
- `nix develop` now exposes only `watch-slide` and `watch-presentable-slide`, both taking a numeric prefix like `05`
- `just sync-slides` copies the current built PDFs into `build/slides/`
- `just sync-presentable` copies the current presentable PDFs into `build/presentable/`

Generated PDFs now live under ignored `build/slides/` and `build/presentable/`. The repository tracks the Typst sources, not the built slide artifacts.

Legacy `::: nonincremental` blocks are still honored when regenerating from markdown, so recap slides and similar sections stay non-animated in presentable mode.

If you need to regenerate the Typst sources from the legacy markdown inputs, `just regenerate-decks` expects the sibling academy repository at `../ucwn-academy-2025`.
