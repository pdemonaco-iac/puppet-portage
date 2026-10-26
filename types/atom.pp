# @summary A Portage package atom, e.g. `>=sys-apps/sed-4.8:0::gentoo`.
#
# Accepts an optional blocker (`!`, `!!`), a version operator (`<`, `<=`, `=`,
# `>=`, `>`, `~`) with a version, a trailing `*` on `=` atoms, a slot with
# an optional subslot and `=`/`*` slot operator (or a bare `:=`/`:*`), and a
# `::repo` constraint.
type Portage::Atom = Pattern[
  /\A!{0,2}[A-Za-z0-9_][A-Za-z0-9_+.-]*\/[A-Za-z0-9_][A-Za-z0-9_+-]*(:[A-Za-z0-9_][A-Za-z0-9_+.-]*(\/[A-Za-z0-9_][A-Za-z0-9_+.-]*)?[=*]?|:[=*])?(::[A-Za-z0-9_][A-Za-z0-9_-]*)?\z/,
  /\A!{0,2}(<=|>=|<|>|=|~)?[A-Za-z0-9_][A-Za-z0-9_+.-]*\/[A-Za-z0-9_][A-Za-z0-9_+-]*-[0-9]+(\.[0-9]+)*[a-z]?(_(alpha|beta|pre|rc|p)[0-9]*)*(-r[0-9]*)?\*?(:[A-Za-z0-9_][A-Za-z0-9_+.-]*(\/[A-Za-z0-9_][A-Za-z0-9_+.-]*)?[=*]?|:[=*])?(::[A-Za-z0-9_][A-Za-z0-9_-]*)?\z/,
]
