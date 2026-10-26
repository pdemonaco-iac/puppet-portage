# @summary A license name, `@GROUP`, or `*` wildcard, optionally negated with `-`.
type Portage::Licensetoken = Pattern[/\A(-?\*|-?@?[A-Za-z0-9][A-Za-z0-9+_.-]*)\z/]
