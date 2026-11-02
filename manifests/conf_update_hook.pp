# @summary Manages one executable hook in conf-update.d/ of a target.
#
# dispatch-conf and other configuration update tools run each hook with
# `pre-session`, `post-session`, or `post-update <path>` (e.g. an etckeeper
# commit hook).
#
# @param root
#   Config root of the owning target.
# @param content
#   Script text, including the shebang line. Exactly one of content and
#   source is required.
# @param source
#   Script file source. Exactly one of content and source is required.
# @param filename
#   Hook name; defaults to the title minus its `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the hook directory.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::conf_update_hook (
  Portage::Targetroot $root,
  Optional[String[1]] $content = undef,
  Optional[Stdlib::Filesource] $source = undef,
  Optional[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  if ($content == undef) == ($source == undef) {
    fail("portage::conf_update_hook[${title}]: exactly one of content and source is required")
  }

  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }
  $dir = "${prefix}/etc/portage/conf-update.d"

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
    source  => $source,
    require => File[$dir],
  }
}
