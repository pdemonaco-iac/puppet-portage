# @summary A /etc/portage/patches/<category>/<dir> name: `cat/pn`, `cat/pn-ver` or `cat/pn-ver-rN`, each with an optional `:slot`.
type Portage::Patchdir = Pattern[
  /\A[A-Za-z0-9_][A-Za-z0-9_+.-]*\/[A-Za-z0-9_][A-Za-z0-9_+-]*(-[0-9]+(\.[0-9]+)*[a-z]?(_(alpha|beta|pre|rc|p)[0-9]*)*(-r[0-9]+)?)?(:[A-Za-z0-9_][A-Za-z0-9_+.-]*)?\z/,
]
