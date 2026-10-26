# @summary Installs the portage-publish script, the served layout and an optional cron job.
#
# Puppet only installs; it never runs a build. `portage-publish` syncs the
# host's repositories, builds @world in every target one after the other, and
# only when all builds succeeded copies the repositories to
# `${mirror_dir}/<repo>` and each target's binary packages to
# `${binhost_dir}/<target>`, then regenerates the binhost indexes. Repository
# metadata is never regenerated, so the published tree stays byte-identical to
# what the signed MetaManifest covers.
#
# @param targets
#   Names of the build targets, built in this order.
# @param repos
#   Repositories under `repos_dir` to publish to the mirror.
# @param emerge_args
#   Arguments passed to `target-emerge <target>`; the packages are built
#   because the targets have FEATURES=buildpkg.
# @param cron_schedule
#   Cron schedule of the publish run, managed as a `cron` resource
#   (puppetlabs-cron_core): `minute` and `hour` are required, `monthday`,
#   `month` and `weekday` default to `*`, and `user` to root. Without it the
#   cron job is removed and the script is run by hand or by another scheduler.
# @param script_path
#   Where to install the script.
# @param target_emerge
#   Path of the target-emerge wrapper.
# @param repos_dir
#   Host repository directory.
# @param mirror_dir
#   Directory the repositories are published to, one subdirectory each.
# @param pkgdir_root
#   Directory holding one PKGDIR per target, as built by target-emerge.
# @param binhost_dir
#   Served binhost directory, one subdirectory of binary packages per target.
# @param lock_file
#   Lock file that keeps two publish runs from overlapping.
class portage::buildhost::publish (
  Array[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.-]*\z/]] $targets = [],
  Array[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $repos = ['gentoo'],
  Array[String[1]] $emerge_args = ['--update', '--deep', '--newuse', '@world'],
  Optional[Portage::Cronschedule] $cron_schedule = undef,
  Stdlib::Unixpath $script_path = '/usr/local/sbin/portage-publish',
  Stdlib::Unixpath $target_emerge = '/usr/local/sbin/target-emerge',
  Stdlib::Unixpath $repos_dir = '/var/db/repos',
  Stdlib::Unixpath $mirror_dir = '/srv/portage-mirror',
  Stdlib::Unixpath $pkgdir_root = '/var/cache/portage-targets',
  Stdlib::Unixpath $binhost_dir = '/srv/binhost',
  Stdlib::Unixpath $lock_file = '/run/lock/portage-publish.lock',
) {
  $directories = [$mirror_dir, $binhost_dir]
  $directories.each |$dir| {
    file { $dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
  }

  $repos.each |$repo| {
    file { "${mirror_dir}/${repo}":
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File[$mirror_dir],
    }
  }

  $targets.each |$target| {
    file { "${binhost_dir}/${target}":
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File[$binhost_dir],
    }
  }

  $script_params = {
    'targets'       => $targets,
    'repos'         => $repos,
    'emerge_args'   => $emerge_args,
    'target_emerge' => $target_emerge,
    'repos_dir'     => $repos_dir,
    'mirror_dir'    => $mirror_dir,
    'pkgdir_root'   => $pkgdir_root,
    'binhost_dir'   => $binhost_dir,
    'lock_file'     => $lock_file,
  }

  file { $script_path:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => epp('portage/portage-publish.epp', $script_params),
  }

  $cron_ensure = $cron_schedule ? {
    undef   => absent,
    default => present,
  }
  $cron = {
    'monthday' => '*',
    'month'    => '*',
    'weekday'  => '*',
    'user'     => 'root',
  } + ($cron_schedule ? { undef => {}, default => $cron_schedule })

  cron { 'portage-publish':
    ensure      => $cron_ensure,
    command     => $script_path,
    environment => ['SHELL=/bin/bash', 'PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'],
    *           => $cron,
    require     => File[$script_path],
  }
}
