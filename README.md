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
* The only `exec` is a `refreshonly` `emaint sync -r <name>`, for host-rooted
  targets.

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
