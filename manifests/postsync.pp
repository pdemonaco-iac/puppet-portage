# @summary Manages one executable hook in postsync.d/ or repo.postsync.d/ of a target.
#
# Hooks run in lexical order of their file names. postsync.d hooks run once
# after all repositories are synced; repo.postsync.d hooks run after each
# repository with the repository name, sync-uri and location as arguments.
#
# @param root
#   Config root of the owning target.
# @param content
#   Script text, including the shebang line.
# @param per_repo
#   Install into repo.postsync.d instead of postsync.d.
# @param filename
#   Hook name; defaults to the title minus its `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the hook directory.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::postsync (
  Portage::Targetroot $root,
  String[1] $content,
  Boolean $per_repo = false,
  Optional[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }
  $kind = $per_repo ? {
    true    => 'repo.postsync.d',
    default => 'postsync.d',
  }
  $dir = "${prefix}/etc/portage/${kind}"

  $entry = $filename ? {
    undef   => regsubst($title, '\A[^/]*/', ''),
    default => $filename,
  }

  unless defined(Portage::Managed_dir[$dir]) {
    portage::managed_dir { $dir:
      purge        => $purge,
      purge_ignore => $purge_ignore,
    }
  }

  file { "${dir}/${entry}":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => $content,
    require => File[$dir],
  }
}
