# @summary An ebuild keyword such as `amd64`, `~amd64`, `-amd64`, `*`, `~*` or `**`.
type Portage::Keyword = Pattern[
  /\A(\*\*|[~-]?\*|[~-]?[a-z0-9]+(-[a-z0-9]+)*)\z/,
]
