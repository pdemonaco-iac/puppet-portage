# @summary One token after the atom in package.use.
#
# A USE flag, `-*`, or an upper-case USE_EXPAND group marker such as
# `PYTHON_TARGETS:` that applies the tokens following it to that group,
# e.g. `['PYTHON_TARGETS:', '-*', 'python3_13']`.
type Portage::Packageuseflag = Variant[
  Portage::Useexpandflag,
  Pattern[/\A[A-Z][A-Z0-9_]*:\z/],
]
