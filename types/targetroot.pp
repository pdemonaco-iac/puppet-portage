# @summary A Portage config root: the host (`/`) or a chroot target.
type Portage::Targetroot = Pattern[
  /\A\/\z/,
  /\A\/var\/lib\/portage-targets\/[A-Za-z0-9_][A-Za-z0-9_.-]*\z/,
]
