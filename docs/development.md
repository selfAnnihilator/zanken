# Documentation Development

Implementation progress is tracked in the [architecture TODO](architecture-todo.md).
The [release model](releases.md) documents stable/dev candidate resolution and
the remaining installation and promotion milestones.

Zanken documentation is a [MkDocs](https://www.mkdocs.org/) site using the
Material theme. Source pages live in `docs/`; the generated `site/` directory
is disposable and is not committed.

## Prerequisites

On Arch Linux, install the packages used by the committed site configuration:

```bash
sudo pacman -S --needed mkdocs mkdocs-material python-pymdown-extensions
```

## Preview locally

Run the development server from the repository root:

```bash
mkdocs serve
```

MkDocs prints the local URL and refreshes the browser when Markdown or
`mkdocs.yml` changes.

## Verify before publishing

Build with warnings treated as errors:

```bash
mkdocs build --strict --clean
```

GitHub Actions runs this validation on both `dev` and `main`. GitHub Pages
deployment is restricted to `main`, after validation succeeds.

The command reference is generated from the metadata in `bin/zanken-*`. Keep
it synchronized whenever command metadata changes:

```bash
zanken dev generate-command-docs
zanken dev generate-command-docs --check
```

## Writing guidelines

* Document the current standalone Zanken behavior, not retired Omarchy
  compatibility paths.
* Prefer stable commands and managed paths over machine-specific details.
* Add a page to `mkdocs.yml` navigation when it is intended for readers rather
  than only for repository maintenance.
