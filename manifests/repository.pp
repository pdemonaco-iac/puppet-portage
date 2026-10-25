# @summary Manages one repos.conf/<name>.conf of a target.
#
# The only exec is a refreshonly `emaint sync -r <name>`, and only for the
# host root (`/`); chroots bind-mount the host's repositories.
#
# @param root
#   Config root of the owning target.
# @param repo_name
#   Repository name (the section name); defaults to the title minus its
#   `<target>/` prefix.
# @param location
#   Repository location; defaults to /var/db/repos/<name>.
# @param sync_type
#   Syncer, or undef to disable syncing.
# @param sync_uri
#   Sync URI; required when sync_type is set.
# @param sync
#   Run `emaint sync -r <name>` when the file changes (host root only).
# @param priority
#   Repository priority.
# @param auto_sync
#   Whether `emerge --sync` / `emaint sync --auto` syncs this repository.
# @param masters
#   Master repositories.
# @param sync_depth
#   Sync depth for DVCS repositories (0 is unlimited).
# @param sync_rsync_verify_metamanifest
#   Require a signed MetaManifest (rsync only). Defaults to true for `gentoo`.
# @param sync_rsync_verify_jobs
#   Parallel verification jobs (rsync only).
# @param sync_rsync_verify_max_age
#   Warn when the repository is older than this many days; 0 disables (rsync only).
# @param sync_rsync_extra_opts
#   Extra rsync options.
# @param sync_openpgp_key_path
#   Keyring used to verify the repository.
# @param sync_git_verify_commit_signature
#   Require a good OpenPGP signature on the top commit (git only).
# @param aliases
#   Aliases of the repository; prefix an alias with `-` to discard it.
# @param clone_depth
#   Clone depth for DVCS repositories (0 is unlimited).
# @param eclass_overrides
#   Repositories this repository inherits eclasses from; an empty array
#   disables overrides.
# @param force
#   Attributes egencache and emirrordist must respect.
# @param strict_misc_digests
#   Check digests of MISC files in the Manifest.
# @param sync_allow_hardlinks
#   Let sync plugins use hardlinks to keep the repository valid on failure.
# @param sync_hooks_only_on_change
#   Only run postsync hooks when the repository changed.
# @param sync_umask
#   Octal umask used to synchronize the repository.
# @param sync_user
#   `[user][:group]` used to perform the synchronization.
# @param sync_rcu
#   Enable read-copy-update sync behavior (rsync only).
# @param sync_rcu_store_dir
#   Directory reserved for sync-rcu storage; unique per repository (rsync only).
# @param sync_rcu_spare_snapshots
#   Expired sync-rcu snapshots to keep (rsync only).
# @param sync_rcu_ttl_days
#   Days to keep previous sync-rcu snapshots (rsync only).
# @param sync_rsync_vcs_ignore
#   Ignore VCS directories in the repository (rsync only).
# @param sync_cvs_repo
#   CVS repository (cvs only).
# @param sync_git_clone_env
#   Environment for `git clone`; quote elements as needed (git only).
# @param sync_git_clone_extra_opts
#   Extra options for `git clone` (git only).
# @param sync_git_env
#   Environment for git clone and pull (git only).
# @param sync_git_pull_env
#   Environment for `git pull` (git only).
# @param sync_git_pull_extra_opts
#   Extra options for `git pull` (git only).
# @param sync_git_verify_max_age_days
#   Warn when the repository is older than this many days (git only).
# @param sync_mercurial_clone_env
#   Environment for `hg clone` (mercurial only).
# @param sync_mercurial_clone_extra_opts
#   Extra options for `hg clone` (mercurial only).
# @param sync_mercurial_env
#   Environment for hg clone and pull (mercurial only).
# @param sync_mercurial_pull_env
#   Environment for `hg pull` (mercurial only).
# @param sync_mercurial_pull_extra_opts
#   Extra options for `hg pull` (mercurial only).
# @param sync_webrsync_delta
#   Use emerge-delta-webrsync (webrsync only).
# @param sync_webrsync_keep_snapshots
#   Keep snapshots in DISTDIR (webrsync only).
# @param sync_webrsync_verify_signature
#   Require a good OpenPGP signature on the tarball (webrsync only).
# @param sync_openpgp_key_package
#   Package providing the keyring in sync_openpgp_key_path.
# @param sync_openpgp_key_refresh
#   Key refresh mode: a Boolean, `wkd`, `keyserver` or `false-nowarn`.
# @param sync_openpgp_key_refresh_retry_count
#   Maximum key refresh retries.
# @param sync_openpgp_key_refresh_retry_delay_exp_base
#   Base of the exponential retry delay.
# @param sync_openpgp_key_refresh_retry_delay_max
#   Maximum delay between retries, in seconds.
# @param sync_openpgp_key_refresh_retry_delay_mult
#   Multiplier of the exponential retry delay.
# @param sync_openpgp_key_refresh_retry_overall_timeout
#   Combined time limit for all refresh attempts, in seconds.
# @param sync_openpgp_keyserver
#   Value passed to `gpg --keyserver`.
# @param usepkg_exclude
#   Package names or slot atoms whose binary packages emerge ignores.
# @param usepkg_include
#   Package names or slot names whose binary packages emerge may use; others
#   are ignored.
# @param volatile
#   Treat the repository as modified outside of Portage.
# @param purge
#   Remove unmanaged files from repos.conf.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::repository (
  Portage::Targetroot $root,
  Optional[Pattern[/\A(?!DEFAULT\z)[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $repo_name = undef,
  Optional[Stdlib::Unixpath] $location = undef,
  Optional[Enum['cvs', 'git', 'mercurial', 'rsync', 'zipfile', 'svn', 'webrsync']] $sync_type = undef,
  Optional[Pattern[/\A[a-z][a-z+]*:\/\/\S+\z/]] $sync_uri = undef,
  Boolean $sync = true,
  Optional[Integer] $priority = undef,
  Optional[Boolean] $auto_sync = undef,
  Optional[Array[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]]] $masters = undef,
  Optional[Integer[0]] $sync_depth = undef,
  Optional[Boolean] $sync_rsync_verify_metamanifest = undef,
  Optional[Integer[1]] $sync_rsync_verify_jobs = undef,
  Optional[Integer[0]] $sync_rsync_verify_max_age = undef,
  Optional[Array[String[1]]] $sync_rsync_extra_opts = undef,
  Optional[Stdlib::Unixpath] $sync_openpgp_key_path = undef,
  Optional[Boolean] $sync_git_verify_commit_signature = undef,
  Optional[Array[Pattern[/\A-?[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]]] $aliases = undef,
  Optional[Integer[0]] $clone_depth = undef,
  Optional[Array[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]]] $eclass_overrides = undef,
  Optional[Array[Enum['aliases', 'eclass-overrides', 'masters']]] $force = undef,
  Optional[Boolean] $strict_misc_digests = undef,
  Optional[Boolean] $sync_allow_hardlinks = undef,
  Optional[Boolean] $sync_hooks_only_on_change = undef,
  Optional[Pattern[/\A0?[0-7]{3}\z/]] $sync_umask = undef,
  Optional[Pattern[/\A([A-Za-z0-9_][A-Za-z0-9_.-]*)?(:[A-Za-z0-9_][A-Za-z0-9_.-]*)?\z/]] $sync_user = undef,
  Optional[Boolean] $sync_rcu = undef,
  Optional[Stdlib::Unixpath] $sync_rcu_store_dir = undef,
  Optional[Integer[0]] $sync_rcu_spare_snapshots = undef,
  Optional[Integer[0]] $sync_rcu_ttl_days = undef,
  Optional[Boolean] $sync_rsync_vcs_ignore = undef,
  Optional[String[1]] $sync_cvs_repo = undef,
  Optional[Array[String[1]]] $sync_git_clone_env = undef,
  Optional[Array[String[1]]] $sync_git_clone_extra_opts = undef,
  Optional[Array[String[1]]] $sync_git_env = undef,
  Optional[Array[String[1]]] $sync_git_pull_env = undef,
  Optional[Array[String[1]]] $sync_git_pull_extra_opts = undef,
  Optional[Integer[0]] $sync_git_verify_max_age_days = undef,
  Optional[Array[String[1]]] $sync_mercurial_clone_env = undef,
  Optional[Array[String[1]]] $sync_mercurial_clone_extra_opts = undef,
  Optional[Array[String[1]]] $sync_mercurial_env = undef,
  Optional[Array[String[1]]] $sync_mercurial_pull_env = undef,
  Optional[Array[String[1]]] $sync_mercurial_pull_extra_opts = undef,
  Optional[Boolean] $sync_webrsync_delta = undef,
  Optional[Boolean] $sync_webrsync_keep_snapshots = undef,
  Optional[Boolean] $sync_webrsync_verify_signature = undef,
  Optional[String[1]] $sync_openpgp_key_package = undef,
  Optional[Variant[Boolean, Enum['wkd', 'keyserver', 'false-nowarn']]] $sync_openpgp_key_refresh = undef,
  Optional[Integer[0]] $sync_openpgp_key_refresh_retry_count = undef,
  Optional[Variant[Integer[0], Float[0.0]]] $sync_openpgp_key_refresh_retry_delay_exp_base = undef,
  Optional[Variant[Integer[0], Float[0.0]]] $sync_openpgp_key_refresh_retry_delay_max = undef,
  Optional[Variant[Integer[0], Float[0.0]]] $sync_openpgp_key_refresh_retry_delay_mult = undef,
  Optional[Variant[Integer[0], Float[0.0]]] $sync_openpgp_key_refresh_retry_overall_timeout = undef,
  Optional[String[1]] $sync_openpgp_keyserver = undef,
  Optional[Array[String[1]]] $usepkg_exclude = undef,
  Optional[Array[String[1]]] $usepkg_include = undef,
  Optional[Boolean] $volatile = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $repo = $repo_name ? {
    undef   => regsubst($title, '\A[^/]*/', ''),
    default => $repo_name,
  }

  if $repo =~ /\ADEFAULT\z/ {
    fail("portage::repository[${title}]: DEFAULT is reserved, use portage::repos_default")
  }
  if $sync_type != undef and $sync_uri == undef {
    fail("portage::repository[${title}]: sync_uri is required when sync_type is set")
  }
  $rsync_params = [
    $sync_rsync_verify_metamanifest,
    $sync_rsync_verify_jobs,
    $sync_rsync_verify_max_age,
    $sync_rsync_extra_opts,
    $sync_rsync_vcs_ignore,
    $sync_rcu,
    $sync_rcu_store_dir,
    $sync_rcu_spare_snapshots,
    $sync_rcu_ttl_days,
  ]
  $git_params = [
    $sync_git_verify_commit_signature,
    $sync_git_clone_env,
    $sync_git_clone_extra_opts,
    $sync_git_env,
    $sync_git_pull_env,
    $sync_git_pull_extra_opts,
    $sync_git_verify_max_age_days,
  ]
  $mercurial_params = [
    $sync_mercurial_clone_env,
    $sync_mercurial_clone_extra_opts,
    $sync_mercurial_env,
    $sync_mercurial_pull_env,
    $sync_mercurial_pull_extra_opts,
  ]
  $webrsync_params = [
    $sync_webrsync_delta,
    $sync_webrsync_keep_snapshots,
    $sync_webrsync_verify_signature,
  ]

  $type_params = {
    'rsync'     => ['sync_rsync_* and sync_rcu*', $rsync_params],
    'git'       => ['sync_git_*', $git_params],
    'mercurial' => ['sync_mercurial_*', $mercurial_params],
    'cvs'       => ['sync_cvs_repo', [$sync_cvs_repo]],
    'webrsync'  => ['sync_webrsync_*', $webrsync_params],
  }
  $type_params.each |$type, $group| {
    if $sync_type != $type and $group[1].any |$value| { $value != undef } {
      fail("portage::repository[${title}]: the ${group[0]} parameters require sync_type ${type}")
    }
  }

  if $sync_rsync_verify_metamanifest == undef and $repo == 'gentoo' and $sync_type == 'rsync' {
    $verify_metamanifest = true
  } else {
    $verify_metamanifest = $sync_rsync_verify_metamanifest
  }

  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }
  $dir = "${prefix}/etc/portage/repos.conf"
  $conf = "${dir}/${repo}.conf"

  $repo_location = $location ? {
    undef   => "/var/db/repos/${repo}",
    default => $location,
  }

  $attributes = {
    'location'                                       => $repo_location,
    'aliases'                                        => $aliases,
    'eclass-overrides'                               => $eclass_overrides,
    'force'                                          => $force,
    'masters'                                        => $masters,
    'priority'                                       => $priority,
    'auto-sync'                                      => $auto_sync,
    'volatile'                                       => $volatile,
    'strict-misc-digests'                            => $strict_misc_digests,
    'usepkg-exclude'                                 => $usepkg_exclude,
    'usepkg-include'                                 => $usepkg_include,
    'sync-type'                                      => $sync_type,
    'sync-uri'                                       => $sync_uri,
    'sync-user'                                      => $sync_user,
    'sync-umask'                                     => $sync_umask,
    'sync-allow-hardlinks'                           => $sync_allow_hardlinks,
    'sync-hooks-only-on-change'                      => $sync_hooks_only_on_change,
    'sync-depth'                                     => $sync_depth,
    'clone-depth'                                    => $clone_depth,
    'sync-rcu'                                       => $sync_rcu,
    'sync-rcu-store-dir'                             => $sync_rcu_store_dir,
    'sync-rcu-spare-snapshots'                       => $sync_rcu_spare_snapshots,
    'sync-rcu-ttl-days'                              => $sync_rcu_ttl_days,
    'sync-rsync-verify-metamanifest'                 => $verify_metamanifest,
    'sync-rsync-verify-jobs'                         => $sync_rsync_verify_jobs,
    'sync-rsync-verify-max-age'                      => $sync_rsync_verify_max_age,
    'sync-rsync-extra-opts'                          => $sync_rsync_extra_opts,
    'sync-rsync-vcs-ignore'                          => $sync_rsync_vcs_ignore,
    'sync-cvs-repo'                                  => $sync_cvs_repo,
    'sync-git-verify-commit-signature'               => $sync_git_verify_commit_signature,
    'sync-git-verify-max-age-days'                   => $sync_git_verify_max_age_days,
    'sync-git-clone-env'                             => $sync_git_clone_env,
    'sync-git-clone-extra-opts'                      => $sync_git_clone_extra_opts,
    'sync-git-env'                                   => $sync_git_env,
    'sync-git-pull-env'                              => $sync_git_pull_env,
    'sync-git-pull-extra-opts'                       => $sync_git_pull_extra_opts,
    'sync-mercurial-clone-env'                       => $sync_mercurial_clone_env,
    'sync-mercurial-clone-extra-opts'                => $sync_mercurial_clone_extra_opts,
    'sync-mercurial-env'                             => $sync_mercurial_env,
    'sync-mercurial-pull-env'                        => $sync_mercurial_pull_env,
    'sync-mercurial-pull-extra-opts'                 => $sync_mercurial_pull_extra_opts,
    'sync-webrsync-delta'                            => $sync_webrsync_delta,
    'sync-webrsync-keep-snapshots'                   => $sync_webrsync_keep_snapshots,
    'sync-webrsync-verify-signature'                 => $sync_webrsync_verify_signature,
    'sync-openpgp-key-package'                       => $sync_openpgp_key_package,
    'sync-openpgp-key-path'                          => $sync_openpgp_key_path,
    'sync-openpgp-key-refresh'                       => $sync_openpgp_key_refresh,
    'sync-openpgp-key-refresh-retry-count'           => $sync_openpgp_key_refresh_retry_count,
    'sync-openpgp-key-refresh-retry-delay-exp-base'  => $sync_openpgp_key_refresh_retry_delay_exp_base,
    'sync-openpgp-key-refresh-retry-delay-max'       => $sync_openpgp_key_refresh_retry_delay_max,
    'sync-openpgp-key-refresh-retry-delay-mult'      => $sync_openpgp_key_refresh_retry_delay_mult,
    'sync-openpgp-key-refresh-retry-overall-timeout' => $sync_openpgp_key_refresh_retry_overall_timeout,
    'sync-openpgp-keyserver'                         => $sync_openpgp_keyserver,
  }.filter |$key, $value| { $value =~ NotUndef }

  unless defined(Portage::Managed_dir[$dir]) {
    portage::managed_dir { $dir:
      purge        => $purge,
      purge_ignore => $purge_ignore,
    }
  }

  file { $conf:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('portage/repo.conf.epp', { 'section' => $repo, 'attributes' => $attributes }),
    require => File[$dir],
  }

  if $root == '/' and $sync and $sync_type != undef {
    exec { "emaint sync -r ${repo}":
      path        => ['/usr/bin', '/usr/sbin', '/bin', '/sbin'],
      refreshonly => true,
      subscribe   => File[$conf],
    }
  }
}
