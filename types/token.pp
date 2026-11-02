# @summary A single whitespace-free item of a space-delimited make.conf list.
type Portage::Token = Pattern[/\A[^\s"]+\z/]
