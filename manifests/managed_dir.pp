# @summary Private: a directory under /etc/portage whose unmanaged content is purged by default.
#
# @param purge
#   Remove unmanaged files from the directory.
# @param purge_ignore
#   File name patterns exempt from purging.
#
# @api private
define portage::managed_dir (
  Boolean $purge = true,
  Array[String[1]] $purge_ignore = [],
) {
  file { $title:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => $purge,
    purge   => $purge,
    ignore  => $purge_ignore,
  }
}
