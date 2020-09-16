# Development

# Build, Lint, Test

Reference `.github/workflows/ci.yml`

```bash
mix format
mix dialyzer
mix credo --all --strict
mix coveralls --trace
```

# Docs

```bash
mix docs
```

`doc/readme.html`

# Example bot script

Run `example/example.exs` with:

```bash
TOKEN="..." mix run example/example.exs
```