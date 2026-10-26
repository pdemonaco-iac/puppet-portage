# portage

Declarative management of Gentoo Portage configuration with OpenVox, for both
ordinary Gentoo nodes and a binary package build host.

> **Status:** pre-release. Unit-tested; not yet acceptance-tested on real nodes.

## Table of Contents

1. [Description](#description)
1. [Setup](#setup)
1. [Usage](#usage)
1. [Intermittently connected nodes](#intermittently-connected-nodes)
1. [Limitations](#limitations)
1. [Reference](#reference)
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
* On the build host: `rsyncd` serving `/srv/portage-mirror/*`, an Apache
  virtual host serving `/srv/binhost`, the `target-emerge` chroot wrapper, the
  `portage-publish` script, and the binpkg signing key.
* The `exec`s are: a `refreshonly` `emaint sync -r <name>` for host-rooted
  targets; on the build host, a `gpg --import` of the binpkg signing key that
  runs only while the key is missing from a root's signing GnuPG home; and, for
  `portage::binhost_key`, `getuto` (only while `/etc/portage/gnupg` does not
  exist) and an import plus local signature of the binhost key (only while the
  key is not yet trusted).

### Setup requirements

* OpenVox 8.x or later (agent and server), with Hiera 5 and eyaml.
* Gentoo on x86-64. Other architectures are out of scope.
* Stage3 bootstrap of build chroots is manual or scripted outside this module.
* Modules: `puppetlabs/stdlib`, `puppetlabs/cron_core` (for the optional
  `portage::buildhost::publish` cron job) and `puppetlabs/apache` (with its
  dependencies `puppetlabs/concat` and `puppet/archive`) for the build host's
  binhost.
* On Gentoo, `puppetlabs/apache` declares the legacy `gentoo/portage` API
  `portage::makeconf { 'apache2_mpms': }`. This module provides that define as a
  shim and writes `APACHE2_MPMS` and `APACHE2_MODULES` into the host's
  `make.conf`, so do not also install the old `gentoo/portage` module.

## Usage

Wrap the module in two profiles:

```puppet
# Every Gentoo node.
class profile::gentoo::portage {
  include portage
}

# The build host: its own host target plus the build targets. portage::buildhost
# declares portage::buildhost::signing, ::publish and ::mirror itself.
class profile::gentoo::buildhost {
  include profile::gentoo::portage
  include portage::buildhost
}
```

Everything else is Hiera data. The `portage::*` hashes deep-merge across Hiera
layers, so common data can set the defaults and a node layer can add to them;
prefix a key with `--` to remove an entry inherited from a lower layer (for
example `--guru:` under `portage::repositories`).

### Consumer

Consumers sync from the build host's rsync mirror and list the build host's
binhost first (higher priority), upstream second. Each consumer with a distinct
USE set needs a matching build host target; here, `desktop`.

```yaml
portage::profile:
  path: default/linux/amd64/23.0/desktop/systemd
portage::make_conf:
  MAKEOPTS: ['-j8']
  FEATURES: [getbinpkg]
portage::repositories:
  gentoo:
    sync_type: rsync
    sync_uri: rsync://buildhost.example.org/gentoo    # MetaManifest verified by default
  guru:
    sync_type: rsync
    sync_uri: rsync://buildhost.example.org/guru
    sync_rsync_verify_metamanifest: false            # git-sourced, unsigned
portage::binrepos:
  buildhost:
    sync_uri: https://buildhost.example.org/desktop
    priority: 10
    verify_signature: true
  upstream:
    sync_uri: https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/
    priority: 1
    verify_signature: true
portage::binhost_keys:
  buildhost:
    fingerprint: 0123456789ABCDEF0123456789ABCDEF01234567   # gpg --fingerprint <key-id>
    public_key: |
      -----BEGIN PGP PUBLIC KEY BLOCK-----
      ...
portage::package_use:
  media:
    entries:
      media-video/ffmpeg: [x264, -doc]
portage::accept_keywords:
  editors:
    entries:
      app-editors/neovim: ['~amd64']
```

### Build host

The build host's own host target syncs from upstream; each build target is a
chroot that mirrors one class of consumer. Put the consumers' USE, keywords and
profile in the matching target so the binpkgs fit them.

```yaml
portage::repositories:
  gentoo:
    sync_type: rsync
    sync_uri: rsync://rsync.gentoo.org/gentoo-portage
  guru:
    sync_type: git
    sync_uri: https://github.com/gentoo-mirror/guru.git
portage::buildhost::targets:
  desktop:
    profile:
      path: default/linux/amd64/23.0/desktop/systemd
    make_conf:
      MAKEOPTS: ['-j16']
    package_use:
      media:
        entries:
          media-video/ffmpeg: [x264, -doc]
    accept_keywords:
      editors:
        entries:
          app-editors/neovim: ['~amd64']
portage::buildhost::publish::repos: [gentoo, guru]
portage::buildhost::publish::cron_schedule:
  minute: '30'
  hour: '2'
portage::buildhost::mirror::hosts_allow: ['192.0.2.0/24']
portage::buildhost::binhost::ssl: true
portage::buildhost::binhost::ssl_cert: /etc/ssl/apache2/binhost.crt
portage::buildhost::binhost::ssl_key: /etc/ssl/apache2/binhost.key
apache::default_vhost: false
```

Targets default to `FEATURES="getbinpkg buildpkg binpkg-signing"` and an
upstream binrepo with signature verification. `portage-publish` copies the
repositories to `/srv/portage-mirror/<repo>` (served by rsyncd) and each
target's binpkgs to `/srv/binhost/<target>`. `portage::buildhost::binhost`
serves `/srv/binhost` read-only through an `apache::vhost`, so each target is
at `https://<servername>/<target>/`, the consumers' `binrepos` `sync_uri`. The
live per-target PKGDIRs are never served. TLS (with an HTTP to HTTPS redirect)
and HTTP basic authentication (`auth_user_file`, an htpasswd file you manage;
consumers put the credentials in their `sync_uri`) are optional. Apache itself
is configured through the `apache` class in Hiera; set
`portage::buildhost::binhost::manage_apache: false` if you declare it elsewhere.

### Bootstrapping a build target

The module never creates a target's root; bootstrap each one from a stage3
before the first run. For a target named `desktop` in
`portage::buildhost::targets`:

1. Pick the stage3 that matches the target's profile (for example `amd64-desktop-systemd`)
   from the [Gentoo downloads page](https://www.gentoo.org/downloads/).
2. Unpack it into the target's root, as in the
   [Handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage):

   ```shell
   mkdir -p /var/lib/portage-targets/desktop
   tar xpf stage3-amd64-desktop-systemd-*.tar.xz --xattrs-include='*.*' \
       --numeric-owner -C /var/lib/portage-targets/desktop
   ```
3. Run the agent. It writes the target's `/etc/portage` (including `make.conf`,
   `repos.conf`, `binrepos.conf` and the signing key) and installs
   `/usr/local/sbin/target-emerge`. The host syncs the repositories; chroots
   only see them read-only.
4. Build with the wrapper, which sets up the
   [chroot](https://wiki.gentoo.org/wiki/Chroot) bind mounts for the run:

   ```shell
   target-emerge desktop --update --deep --newuse @world
   ```
   Packages come from the upstream binhost where the USE flags match and are
   compiled otherwise; see the
   [Binary package guide](https://wiki.gentoo.org/wiki/Binary_package_guide).
   If upstream signature verification fails because the target has no keyring
   yet, run `chroot /var/lib/portage-targets/desktop getuto` once.

Keep the target's profile aligned with the upstream binhost's (23.0, the same
init system) to maximise binary package hits, and keep GCC current.

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
portage::buildhost::signing::key_id: '0x40DCF18E97150795'
portage::buildhost::signing::public_key: |
  -----BEGIN PGP PUBLIC KEY BLOCK-----
  ...
portage::buildhost::signing::private_key: ENC[PKCS7,...]
```

`portage::buildhost` sets the signing roots to its targets. The module
converts `private_key` to `Sensitive`, so it never appears in
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

## Intermittently connected nodes

A laptop that is often off the LAN works as an ordinary consumer:

* **Cached catalog.** When the OpenVox server is unreachable, the agent
  reapplies its cached catalog (`usecacheonfailure`, on by default). That is
  safe here: the consumer's resources are files and symlinks, and its only
  execs are the `refreshonly` repository sync and the one-time binhost key
  import, neither of which fires without a change.
* **Stale tree off-LAN.** `emaint sync` against the build host fails off-LAN
  and the local tree stays usable, only stale. Do not switch `sync_uri` with
  the network: the consumer must only see the published snapshot, which never
  runs ahead of the build host's binpkgs.
* **Binhosts off-LAN.** The upstream binrepo (second priority) still provides
  packages whose USE flags match; the rest compile locally.
* **Full function off-LAN.** Make the rsync mirror and the binhost reachable
  over a VPN; this is the preferred option. A reverse proxy such as HAProxy can
  front the HTTPS binhost (binpkgs are signed; add authentication if needed),
  but rsync (873/tcp) is not HTTP: HAProxy would need TCP mode for it, or use
  rsync over SSH instead.
* **Its own target.** Give the laptop its own build host target if its profile
  or USE flags differ from the other consumers'. A profile that matches the
  upstream binhost (for example 23.0 desktop with systemd) raises upstream hits.
* **Managed machines.** If another organisation manages the machine, check
  that it permits an OpenVox agent; otherwise configure it by hand as a
  Portage-only consumer of the mirror and binhost.

## Limitations

* Gentoo only; x86-64 only.
* Patches apply on the next rebuild; changing them triggers no rebuild.
* Git-sourced overlays carry no signed MetaManifest, so consumers cannot verify
  them over rsync.
* Off-LAN consumers keep a stale but usable tree; the build host must be
  reachable (for example over VPN) for full function.

## Reference

See [`REFERENCE.md`](REFERENCE.md) for every class, defined type and data type,
generated with Puppet Strings (`bundle exec rake strings:generate:reference`).

## Development

Uses the OpenVox standard tools, [jig](https://github.com/voxpupuli/jig) and
[voxbox](https://github.com/voxpupuli/container-voxbox):

```bash
jig validate
jig test unit
```

Commits follow conventional commit syntax. Open design questions and
unverified assumptions are tracked as GitHub issues.
