# portage

Declarative management of Gentoo Portage configuration with OpenVox, for both
ordinary Gentoo nodes and a binary package build host.

> **Status:** design phase. See [`portage-module-plan.md`](portage-module-plan.md);
> most of what is described below is not implemented yet.

## Table of Contents

1. [Description](#description)
1. [Setup](#setup)
1. [Usage](#usage)
1. [Limitations](#limitations)
1. [Development](#development)

## Description

The module lays down Portage configuration only. It never runs builds or
`emerge @world`. It serves two roles:

* **Consumers** — Gentoo nodes whose `/etc/portage` is managed from Hiera.
* **Build host** — produces signed binpkgs from per-target chroots, and serves
  a published rsync mirror of the repositories plus a binhost to consumers.

Everything is keyed off a *config root*. The `portage::target` defined type owns
one complete config root: the host is `portage::target { 'host': root => '/' }`,
and each build chroot is the same type rooted at
`/var/lib/portage-targets/<name>`. Both `class portage` (host target) and
`class portage::buildhost` (a `targets` hash, one target per chroot) accept the
same parameter schema.

Managed per target: `make.conf` (rendered from a single hash), the
`make.profile` symlink (relative, so it is valid inside a chroot), `repos.conf`,
`binrepos.conf`, and the `package.*`, `env`, `sets`, `patches` and `postsync.d`
directories. The module does not use `eselect profile` or `eselect repository`.

## Setup

### What portage affects

* Files and directories under `/etc/portage` of each target root. Managed
  directories are **purged by default**; `/etc/portage/gnupg` is never purged.
  Run `--noop` before the first apply on an existing node.
* On the build host: `rsyncd` serving `/srv/portage-mirror/*`, the
  `target-emerge` chroot wrapper, the `portage-publish` script, and the
  binpkg signing key.
* There are two `exec`s: a `refreshonly` `emaint sync -r <name>` for host-rooted
  targets, and, on the build host, a `gpg --import` of the binpkg signing key
  that runs only while the key is missing from a root's signing GnuPG home.

### Setup requirements

* OpenVox 8.x or later (agent and server), with Hiera 5 and eyaml.
* Gentoo on x86-64. Other architectures are out of scope.
* Stage3 bootstrap of build chroots is manual or scripted outside this module.

## Usage

```puppet
include portage
```

```puppet
include portage::buildhost
```

Both are configured through Hiera, using deep merge with `knockout_prefix: '--'`
for `portage::*` hashes. Consumers point `repos.conf` at the build host's rsync
mirror and list the build host first, upstream second, in `binrepos`. Each
consumer with a distinct USE set needs a matching build host target.

### Build host signing key

The build host signs binpkgs with a dedicated key that has no passphrase.
Generate it on a trusted machine, not on the build host:

```shell
gpg --homedir "$(mktemp -d)" --batch --passphrase '' \
    --quick-generate-key 'Binpkg signing <binpkg@example.org>' ed25519 sign never
gpg --list-secret-keys --keyid-format long          # note the key ID or fingerprint
gpg --armor --export-secret-keys <key-id>           # private_key
gpg --armor --export <key-id>                       # public_key
```

Encrypt the private key with [hiera-eyaml](https://github.com/voxpupuli/hiera-eyaml)
(`eyaml encrypt -s` or `-f`), then set the data for `portage::buildhost::signing`:

```yaml
portage::buildhost::signing::roots: [/var/lib/portage-targets/stage3]
portage::buildhost::signing::key_id: '0x40DCF18E97150795'
portage::buildhost::signing::public_key: |
  -----BEGIN PGP PUBLIC KEY BLOCK-----
  ...
portage::buildhost::signing::private_key: ENC[PKCS7,...]
```

The module converts `private_key` to `Sensitive`, so it never appears in
catalogs, reports or logs. Each root gets a `0700` GnuPG home at
`/etc/portage/binpkg-signing`; `portage::buildhost::signing::make_conf` holds
the `FEATURES="binpkg-signing"`, `BINPKG_GPG_SIGNING_GPG_HOME` and
`BINPKG_GPG_SIGNING_KEY` settings for every signing target, and
`portage::buildhost::signing::public_key` is the key to distribute to
consumers. Supporting documentation:

* [Gentoo wiki: Binary package guide](https://wiki.gentoo.org/wiki/Binary_package_guide)
  (signing and verifying binpkgs)
* [make.conf(5)](https://dev.gentoo.org/~zmedico/portage/doc/man/make.conf.5.html):
  `BINPKG_GPG_SIGNING_*` and the `binpkg-signing` feature
* [GnuPG: unattended key generation](https://www.gnupg.org/documentation/manuals/gnupg/Unattended-GPG-key-generation.html)
* [hiera-eyaml](https://github.com/voxpupuli/hiera-eyaml)

## Limitations

* Gentoo only; x86-64 only.
* Patches apply on the next rebuild; changing them triggers no rebuild.
* Git-sourced overlays carry no signed MetaManifest, so consumers cannot verify
  them over rsync.
* Off-LAN consumers keep a stale but usable tree; the build host must be
  reachable (for example over VPN) for full function.

## Development

Uses the OpenVox standard tools, [jig](https://github.com/voxpupuli/jig) and
[voxbox](https://github.com/voxpupuli/container-voxbox):

```bash
jig validate
jig test unit
```

Commits follow conventional commit syntax. The design and the list of items
still to verify are in [`portage-module-plan.md`](portage-module-plan.md).
