# @summary Compatibility shim for the legacy gentoo/portage `portage::makeconf` API.
#
# puppetlabs-apache declares `portage::makeconf { 'apache2_mpms': }` and
# `{ 'apache2_modules': }` on Gentoo. This define accepts those declarations
# and the host target writes them to /etc/portage/make.conf as APACHE2_MPMS
# and APACHE2_MODULES. It declares nothing itself, and only the variables
# listed below are accepted, so nothing is silently dropped. Prefer
# `portage::make_conf` for your own variables.
#
# The values are read when the host portage::target is evaluated, so declare
# the shim from a class (as apache does), not from inside a defined type.
#
# @param content
#   Value of the variable; arrays are space-joined.
# @param ensure
#   `absent` leaves the variable out of make.conf.
# @param variable
#   Lowercase variable name; the title.
define portage::makeconf (
  Variant[String, Array[String]] $content,
  Enum['present', 'absent'] $ensure = 'present',
  Enum['apache2_modules', 'apache2_mpms'] $variable = $title,
) {}
