# @summary Manages the make.profile symlink of a target.
#
# The link is relative (`../../var/db/repos/<repo>/profiles/<path>`) so it
# resolves from the host and from inside a chroot that bind-mounts the host's
# repositories. `eselect profile` is not used.
#
# @param root
#   Config root of the owning target.
# @param path
#   Profile path below the repository's profiles/ directory, e.g.
#   `default/linux/amd64/23.0/systemd`.
# @param repo
#   Repository providing the profile.
define portage::profile (
  Portage::Targetroot $root,
  Pattern[/\A(?!.*(\A|\/)\.\.?(\/|\z))[A-Za-z0-9_][A-Za-z0-9_.+-]*(\/[A-Za-z0-9_][A-Za-z0-9_.+-]*)*\z/] $path,
  Pattern[/\A[A-Za-z0-9_][A-Za-z0-9_.+-]*\z/] $repo = 'gentoo',
) {
  $prefix = $root ? {
    '/'     => '',
    default => $root,
  }

  file { "${prefix}/etc/portage/make.profile":
    ensure => link,
    target => "../../var/db/repos/${repo}/profiles/${path}",
  }
}
