# @summary A USE flag or USE_EXPAND value, or `-*` to clear every inherited value.
type Portage::Useexpandflag = Variant[
  Portage::Useflag,
  Enum['-*'],
]
