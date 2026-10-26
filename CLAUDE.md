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

Design and usage: `README.md`; per-class and per-type docs: `REFERENCE.md` (Puppet Strings, regenerate with `bundle exec rake strings:generate:reference`). Read them before adding code.

### Purpose

Declaratively manage Gentoo Portage configuration on consumer nodes and on a build host that produces signed binpkgs and serves an rsync repo mirror plus binhost. Puppet writes configuration only; it never runs builds or `emerge @world`.

### Module Structure

- Everything is keyed off a config root. `portage::target` (defined type) owns one root: host is `root => '/'`, chroots are `/var/lib/portage-targets/<name>`. Inner resource titles are `"${target}/${key}"`.
- `class portage` -> host target from Hiera. `class portage::buildhost` -> `targets` hash, one target per chroot (plus `buildhost::mirror`, `::publish`, `::signing`, `::binhost`). Both take the same parameter schema.
- Per-resource defined types: `repository`, `profile`, `binrepo`, `binhost_key`, `set`, `package_use`, `accept_keywords`, `license`, `mask`, `package_env`, `env`, `patch`, `postsync`. `makeconf_file` (private) renders `make.conf` from one hash via EPP; `makeconf` is a public shim for the legacy gentoo/portage API that puppetlabs-apache calls on Gentoo (APACHE2_* into the host make.conf); `atomfile` is the private generic.
- Type aliases validate atoms, USE flags, keywords; reject `-march=native` in non-host targets.

### Conventions

- No `eselect profile` / `eselect repository`: `make.profile` is a relative symlink; one `repos.conf/<name>.conf` per repo.
- Managed dirs purge by default (`purge_ignore` escape hatch); never purge `/etc/portage/gnupg`.
- Execs are limited to: `refreshonly` `emaint sync -r <name>` (host-rooted targets only); the `unless`-guarded `gpg --import` of the binpkg signing key (`buildhost::signing`); and, in `binhost_key`, `getuto` (`creates` the keyring) plus the `unless`-guarded import and local signing of a binhost key.
- Repo transport is rsync end to end (upstream -> build host -> consumers). Chroots bind-mount the host repos read-only; only the host syncs.
- Hiera `lookup_options` deep merge with `knockout_prefix: '--'` for `portage::*` hashes.

### Platform Support

- Gentoo only, x86-64 only. OpenVox 8.x+.
- Code must be clean under OpenVox 8 defaults: `strict = error`, `strict_variables = true`, structured facts only (`$facts['os']['family']`), typed parameters, `stdlib::` namespaced functions, no `puppetlabs-concat` in this module's code (it is present only as a transitive dependency of `puppetlabs-apache`), Ruby 3.2+ for custom facts/functions.
