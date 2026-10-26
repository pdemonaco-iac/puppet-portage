# @summary Manages one user patch under /etc/portage/patches/ of a target.
#
# Patches are applied the next time the package is built; nothing here
# triggers a rebuild.
#
# @param root
#   Config root of the owning target.
# @param package
#   Patch directory below the category: `cat/pn`, `cat/pn-ver[-rN]`, each with
#   an optional `:slot`.
# @param content
#   Patch text. Exactly one of content and source is required.
# @param source
#   Patch file source. Exactly one of content and source is required.
# @param filename
#   File name ending in `.patch` or `.diff`; defaults to the title minus its
#   `<target>/` prefix.
# @param purge
#   Remove unmanaged files from the patches directory.
# @param purge_ignore
#   File name patterns exempt from purging.
define portage::patch (
  Portage::Targetroot $root,
  Portage::Patchdir $package,
  Optional[String[1]] $content = undef,
  Optional[Stdlib::Filesource] $source = undef,
  Optional[Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\.(patch|diff)\z/]] $filename = undef,
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  if ($content == undef) == ($source == undef) {
    fail("portage::patch[${title}]: exactly one of content and source is required")
  }

  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }
  $dir = "${prefix}/etc/portage/patches"
  $category = regsubst($package, '/.*\z', '')

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

  unless defined(File["${dir}/${category}"]) {
    file { "${dir}/${category}":
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File[$dir],
    }
  }

  unless defined(File["${dir}/${package}"]) {
    file { "${dir}/${package}":
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File["${dir}/${category}"],
    }
  }

  file { "${dir}/${package}/${entry}":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $content,
    source  => $source,
    require => File["${dir}/${package}"],
  }
}
