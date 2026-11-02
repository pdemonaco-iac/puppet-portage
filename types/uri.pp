# @summary A fetch URI (`http`, `https`, `ftp`, `rsync`, `sftp`, `ssh`) or an absolute mirror path.
type Portage::Uri = Variant[
  Stdlib::HTTPUrl,
  Stdlib::Unixpath,
  Pattern[/\A(ftp|rsync|sftp|ssh):\/\/[^\s"]+\z/],
]
