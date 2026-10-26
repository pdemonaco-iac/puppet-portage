# @summary Manages the build host: one portage::target per chroot, the signing key and target-emerge.
#
# Each key of `targets` is a chroot under /var/lib/portage-targets; bootstrapping
# its stage3 is out of scope. A target's hash takes the portage::target
# parameters except `root`. Every target defaults to
# `FEATURES="getbinpkg buildpkg binpkg-signing"` and an `upstream` binrepo with
# signature verification; a target's own `make_conf` keys and `binrepos` entries
# override those defaults (set FEATURES in a target to replace it entirely).
#
# @param targets
#   Chroot name mapped to its portage::target parameters.
# @param signing
#   Install the binpkg signing key into every target (portage::buildhost::signing)
#   and add `binpkg-signing` and its settings to every target's make.conf. Has
#   no effect while `targets` is empty.
# @param upstream_binrepo
#   Parameters of the `upstream` portage::binrepo added to every target;
#   `sync_uri` is required.
# @param publish
#   Install the portage-publish script and the served layout
#   (portage::buildhost::publish) for every target.
# @param mirror
#   Serve the published repositories over rsyncd (portage::buildhost::mirror).
#   With `publish` it serves the same repositories and mirror directory.
# @param binhost
#   Serve the published binary packages over HTTP(S) (portage::buildhost::binhost).
#   With `publish` it serves publish's `binhost_dir`.
# @param manage_wrapper
#   Install the target-emerge wrapper.
# @param wrapper_path
#   Where to install the wrapper.
# @param repos_dir
#   Host repository directory, bind-mounted read-only into every chroot.
# @param distfiles_dir
#   Host distfiles directory shared by every chroot.
# @param pkgdir_root
#   Directory holding one PKGDIR per target, bind-mounted at /var/cache/binpkgs
#   in the chroot.
#
# @example Hiera data
#   portage::buildhost::targets:
#     desktop:
#       profile:
#         path: default/linux/amd64/23.0/desktop/systemd
#       make_conf:
#         MAKEOPTS: ['-j8']
class portage::buildhost (
  Hash[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.-]*\z/], Hash[String[1], Any]] $targets = {},
  Boolean $signing = true,
  Hash[String[1], Any] $upstream_binrepo = {
    'sync_uri'         => 'https://distfiles.gentoo.org/releases/amd64/binpackages/23.0/x86-64-v3/',
    'priority'         => 1,
    'verify_signature' => true,
  },
  Boolean $publish = true,
  Boolean $mirror = true,
  Boolean $binhost = true,
  Boolean $manage_wrapper = true,
  Stdlib::Unixpath $wrapper_path = '/usr/local/sbin/target-emerge',
  Stdlib::Unixpath $repos_dir = '/var/db/repos',
  Stdlib::Unixpath $distfiles_dir = '/var/cache/distfiles',
  Stdlib::Unixpath $pkgdir_root = '/var/cache/portage-targets',
) {
  $targets_dir = '/var/lib/portage-targets'
  $roots = $targets.keys.map |$name| { "${targets_dir}/${name}" }

  if $signing and !$roots.empty {
    class { 'portage::buildhost::signing':
      roots => $roots,
    }
    $signing_conf = $portage::buildhost::signing::make_conf
  } else {
    $signing_conf = {}
  }

  $features = ['getbinpkg', 'buildpkg'] + $signing_conf.get('FEATURES', [])

  file { $pkgdir_root:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  $targets.each |$name, $params| {
    $make_conf = { 'FEATURES' => $features } + ($signing_conf - 'FEATURES') + $params.get('make_conf', {})
    $binrepos = { 'upstream' => $upstream_binrepo } + $params.get('binrepos', {})

    portage::target { $name:
      * => $params + { 'root' => "${targets_dir}/${name}", 'make_conf' => $make_conf, 'binrepos' => $binrepos },
    }

    file { "${pkgdir_root}/${name}":
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File[$pkgdir_root],
    }
  }

  if $publish {
    class { 'portage::buildhost::publish':
      targets       => $targets.keys,
      target_emerge => $wrapper_path,
      repos_dir     => $repos_dir,
      pkgdir_root   => $pkgdir_root,
    }
  }

  if $mirror {
    if $publish {
      class { 'portage::buildhost::mirror':
        repos      => $portage::buildhost::publish::repos,
        mirror_dir => $portage::buildhost::publish::mirror_dir,
        repos_dir  => $repos_dir,
        require    => Class['portage::buildhost::publish'],
      }
    } else {
      class { 'portage::buildhost::mirror':
        repos_dir => $repos_dir,
      }
    }
  }

  if $binhost {
    if $publish {
      class { 'portage::buildhost::binhost':
        binhost_dir => $portage::buildhost::publish::binhost_dir,
        pkgdir_root => $pkgdir_root,
        require     => Class['portage::buildhost::publish'],
      }
    } else {
      class { 'portage::buildhost::binhost':
        pkgdir_root => $pkgdir_root,
      }
    }
  }

  if $manage_wrapper {
    $wrapper_params = {
      'targets_dir'   => $targets_dir,
      'repos_dir'     => $repos_dir,
      'distfiles_dir' => $distfiles_dir,
      'pkgdir_root'   => $pkgdir_root,
    }

    file { $wrapper_path:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => epp('portage/target-emerge.epp', $wrapper_params),
    }
  }
}
