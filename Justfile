set quiet

slides_dir := "build/slides"
presentable_dir := "build/presentable"

alias b  := build
alias bs := build-slide
alias ba := build-all
alias bp := build-presentable
alias bps := build-presentable-slide
alias bsp := build-presentable-slide
alias bap := build-all-presentable
alias bpa := build-all-presentable
alias build-slide-presentable := build-presentable-slide
alias build-presentable-all   := build-all-presentable
alias w  := watch
alias ws := watch-slide
alias wp := watch-presentable
alias wps := watch-presentable-slide
alias ss := sync-slides
alias sp := sync-presentable
alias h  := help
alias rd := regenerate-decks

# Build the default handout deck set
default:
  just build-all

# Build one handout deck or the full handout set
build deck="":
  #!/usr/bin/env sh
  set -eu
  if [ -z "{{deck}}" ]
  then
      nix build
  else
      nix build ".#{{deck}}"
  fi

# Build one presentable deck or the full presentable set
build-presentable deck="":
  #!/usr/bin/env sh
  set -eu
  if [ -z "{{deck}}" ]
  then
      nix build .#presentable
  else
      nix build ".#{{deck}}-presentable"
  fi

# Build the first handout deck whose directory starts with NUMBER
build-slide number:
  #!/usr/bin/env sh
  set -eu
  deck=$(find decks -maxdepth 1 -mindepth 1 -type d -name '{{number}}*' | sort | head -n 1)
  if [ -z "$deck" ]
  then
      echo "No deck found for prefix {{number}}" >&2
      exit 1
  fi
  just build "${deck##*/}"

# Build the first presentable deck whose directory starts with NUMBER
build-presentable-slide number:
  #!/usr/bin/env sh
  set -eu
  deck=$(find decks -maxdepth 1 -mindepth 1 -type d -name '{{number}}*' | sort | head -n 1)
  if [ -z "$deck" ]
  then
      echo "No deck found for prefix {{number}}" >&2
      exit 1
  fi
  just build-presentable "${deck##*/}"

# Build the full handout PDF set
build-all:
  nix build

# Build the full presentable PDF set
build-all-presentable:
  nix build .#presentable

# Watch a single handout deck into build/slides/DECK.pdf
watch deck:
  #!/usr/bin/env sh
  set -eu
  mkdir -p "{{slides_dir}}"
  nix develop -c watch-slide "{{deck}}" "{{slides_dir}}/{{deck}}.pdf"

# Watch a single presentable deck into build/presentable/DECK.pdf
watch-presentable deck:
  #!/usr/bin/env sh
  set -eu
  mkdir -p "{{presentable_dir}}"
  nix develop -c watch-presentable-slide "{{deck}}" "{{presentable_dir}}/{{deck}}.pdf"

# Watch the first handout deck whose directory starts with NUMBER
watch-slide number:
  #!/usr/bin/env sh
  set -eu
  nix develop -c watch-slide "{{number}}"

# Watch the first presentable deck whose directory starts with NUMBER
watch-presentable-slide number:
  #!/usr/bin/env sh
  set -eu
  nix develop -c watch-presentable-slide "{{number}}"

# Build all handout PDFs and copy them into build/slides
sync-slides:
  #!/usr/bin/env sh
  set -eu
  mkdir -p "{{slides_dir}}"
  nix build
  cp -fL result/*.pdf "{{slides_dir}}/"

# Build all presentable PDFs and copy them into build/presentable
sync-presentable:
  #!/usr/bin/env sh
  set -eu
  mkdir -p "{{presentable_dir}}"
  nix build .#presentable
  cp -fL result/*.pdf "{{presentable_dir}}/"

# Re-import and re-convert all deck sources from the legacy markdown repos
regenerate-decks:
  nix develop -c python scripts/generate_decks.py

# Show the available commands and their doc comments
help:
  @just --justfile {{justfile()}} --list --unsorted
