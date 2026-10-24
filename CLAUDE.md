# RULES
- CONSTRAINTS: Keep changes minimal; don’t refactor unrelated code; no new deps.
- OUTPUT: (1) files changed list (2) patch (3) short rationale.
- DON’T: explain basics, restate prompt, or list possibilities.
- Before editing code: give a plan in <=5 bullets, each <=12 words. Then implement. No extra commentary.

# Workflow
- Always perform lint checks when you are done making a series of changes
- Prefer single tests, not the entire suite, for performance
- Do not evaluate acceptance tests unless asked

# Code style
- Use conventional commit syntax for commit messages

## Build & Test Commands

Uses the OpenVox standard tools: [jig](https://github.com/voxpupuli/jig) (`jig -h` for help) and [voxbox](https://github.com/voxpupuli/container-voxbox).

### Validate Puppet syntax

```bash
jig validate

# or via voxbox (rake validate / lint)
podman run -it --rm -v $PWD:/repo:Z ghcr.io/voxpupuli/voxbox:latest validate
podman run -it --rm -v $PWD:/repo:Z ghcr.io/voxpupuli/voxbox:latest lint
```

### Unit Tests

```bash
# Run all unit tests
jig test unit

# Run a single unit test file via voxbox
podman run -it --rm -e "SPEC=spec/classes/example_spec.rb" -v $PWD:/repo:Z ghcr.io/voxpupuli/voxbox:latest spec
```

CI (`.github/workflows/20_lint-and-unit.yml`) uses `voxpupuli/gha-puppet`.

### Acceptance Tests

```bash
# Deploy the module to the test nodes
pdk bundle exec rake litmus:install_module

# Run all acceptance tests
pdk bundle exec rake litmus:acceptance:parallel

# Run a single acceptance test
pdk-litmus-test spec/acceptance/kea_dhcp_spec.json
```

## Architecture

### Module Structure

The module follows the standard Puppet pattern with `install` -> `config` -> `service` class ordering:

### Custom Resource Types

The module provides custom types in `lib/puppet/type/`:


### Platform Support

Gentoo only (irrelevant elsewhere)