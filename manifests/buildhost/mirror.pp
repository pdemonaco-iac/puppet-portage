# @summary Serves the published repository snapshot over rsyncd.
#
# rsyncd.conf gets one read-only module per published repository, each rooted
# at `${mirror_dir}/<repo>` (the snapshot portage-publish writes). The live
# repositories under `repos_dir` are never exposed: `mirror_dir` may not
# overlap them, and module paths can only point below `mirror_dir`.
# Consumers sync with `sync-uri = rsync://<buildhost>/<repo>`.
#
# @param repos
#   Published repositories, one rsync module each (including overlays such as guru).
# @param module_aliases
#   Extra module names mapped to one of `repos`, e.g. `{ 'gentoo-portage' => 'gentoo' }`
#   to keep an older sync-uri working.
# @param mirror_dir
#   Directory holding the published snapshot, one subdirectory per repository.
# @param repos_dir
#   The host's live repository directory, which must never be served.
# @param hosts_allow
#   Hosts or networks allowed to connect; everyone else is denied. Empty
#   allows every host.
# @param exclude
#   rsync exclude patterns applied to every module.
# @param max_connections
#   Maximum simultaneous connections; 0 is unlimited.
# @param use_chroot
#   Chroot rsyncd into each module's path.
# @param uid
#   User rsyncd reads files as.
# @param gid
#   Group rsyncd reads files as.
# @param motd
#   Message of the day shown to clients; no motd file without it.
# @param motd_file
#   Where the motd is written.
# @param pid_file
#   rsyncd pid file.
# @param config_file
#   rsyncd configuration file.
# @param manage_package
#   Install the rsync package.
# @param package_name
#   rsync package.
# @param service_name
#   rsyncd service.
class portage::buildhost::mirror (
  Array[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/], 1] $repos = ['gentoo'],
  Hash[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/], Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $module_aliases = {},
  Stdlib::Unixpath $mirror_dir = '/srv/portage-mirror',
  Stdlib::Unixpath $repos_dir = '/var/db/repos',
  Array[Pattern[/\A[0-9A-Za-z.:\/*-]+\z/]] $hosts_allow = [],
  Array[Pattern[/\A\S+\z/]] $exclude = ['.git/'],
  Integer[0] $max_connections = 5,
  Boolean $use_chroot = true,
  String[1] $uid = 'nobody',
  String[1] $gid = 'nobody',
  Optional[String[1]] $motd = undef,
  Stdlib::Unixpath $motd_file = '/etc/rsync/rsyncd.motd',
  Stdlib::Unixpath $pid_file = '/run/rsyncd.pid',
  Stdlib::Unixpath $config_file = '/etc/rsyncd.conf',
  Boolean $manage_package = true,
  String[1] $package_name = 'net-misc/rsync',
  String[1] $service_name = 'rsyncd',
) {
  $mirror = "${mirror_dir.regsubst('/+\z', '')}/"
  $live = "${repos_dir.regsubst('/+\z', '')}/"
  if $mirror.stdlib::start_with($live) or $live.stdlib::start_with($mirror) {
    fail("portage::buildhost::mirror: mirror_dir ${mirror_dir} overlaps the live repositories in ${repos_dir}")
  }

  $module_aliases.each |$name, $repo| {
    unless $repo in $repos {
      fail("portage::buildhost::mirror: module alias ${name} points to ${repo}, which is not in repos")
    }
    if $name in $repos {
      fail("portage::buildhost::mirror: module alias ${name} collides with a repository of the same name")
    }
  }

  $repo_modules = $repos.reduce({}) |$memo, $repo| {
    $memo + { $repo => { 'path' => "${mirror_dir}/${repo}", 'comment' => "Published snapshot of the ${repo} repository" } }
  }
  $alias_modules = $module_aliases.reduce({}) |$memo, $entry| {
    $memo + { $entry[0] => { 'path' => "${mirror_dir}/${entry[1]}", 'comment' => "Published snapshot of the ${entry[1]} repository (alias)" } }
  }

  if $manage_package {
    package { $package_name:
      ensure => installed,
      before => [File[$config_file], Service[$service_name]],
    }
  }

  if $motd =~ NotUndef {
    $motd_dir = $motd_file.regsubst('/[^/]+\z', '')

    file { $motd_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    file { $motd_file:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "${motd.regsubst('\n+\z', '')}\n",
      notify  => Service[$service_name],
    }
  }

  $config_params = {
    'pid_file'        => $pid_file,
    'max_connections' => $max_connections,
    'use_chroot'      => $use_chroot,
    'uid'             => $uid,
    'gid'             => $gid,
    'motd_file'       => $motd ? { undef => undef, default => $motd_file },
    'hosts_allow'     => $hosts_allow,
    'exclude'         => $exclude,
    'modules'         => $repo_modules + $alias_modules,
  }

  file { $config_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('portage/rsyncd.conf.epp', $config_params),
    notify  => Service[$service_name],
  }

  service { $service_name:
    ensure => running,
    enable => true,
  }
}
