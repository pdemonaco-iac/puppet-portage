# @summary A USE flag, optionally disabled with a leading `-`.
type Portage::Useflag = Pattern[/\A-?[A-Za-z0-9][A-Za-z0-9+_@-]*\z/]
