# @summary Serves the published binary packages to consumers over HTTP(S) with Apache.
#
# One apache::vhost serves `binhost_dir` read-only, so each target's packages
# are at `<scheme>://<servername>/<target>/`, the `sync_uri` of a consumer's
# binrepo. Only the published copy is served: the live per-target PKGDIRs
# under `pkgdir_root` are never exposed, and `binhost_dir` may not overlap
# them. Apache itself is configured through the `apache` class (Hiera
# `apache::*`); set `manage_apache` to false to declare it elsewhere.
#
# @param binhost_dir
#   Published binhost directory, one subdirectory per target.
# @param pkgdir_root
#   Directory holding the live per-target PKGDIRs, which must never be served.
# @param servername
#   Virtual host name consumers use in their binrepo `sync_uri`.
# @param ssl
#   Serve over HTTPS with `ssl_cert` and `ssl_key`.
# @param ssl_cert
#   TLS certificate; required when `ssl` is true.
# @param ssl_key
#   TLS private key; required when `ssl` is true.
# @param ssl_chain
#   Optional TLS certificate chain.
# @param redirect_http
#   With `ssl`, add a port 80 vhost that redirects to HTTPS.
# @param port
#   Port of the binhost vhost; defaults to 443 with `ssl`, 80 otherwise.
# @param auth_user_file
#   htpasswd file enabling HTTP basic authentication; the file itself is not
#   managed. Consumers put the credentials in their binrepo `sync_uri`.
# @param auth_name
#   Basic authentication realm.
# @param manage_apache
#   Include the `apache` class.
class portage::buildhost::binhost (
  Stdlib::Unixpath $binhost_dir = '/srv/binhost',
  Stdlib::Unixpath $pkgdir_root = '/var/cache/portage-targets',
  Stdlib::Fqdn $servername = $facts['networking']['fqdn'],
  Boolean $ssl = false,
  Optional[Stdlib::Unixpath] $ssl_cert = undef,
  Optional[Stdlib::Unixpath] $ssl_key = undef,
  Optional[Stdlib::Unixpath] $ssl_chain = undef,
  Boolean $redirect_http = true,
  Optional[Stdlib::Port] $port = undef,
  Optional[Stdlib::Unixpath] $auth_user_file = undef,
  String[1] $auth_name = 'Portage binhost',
  Boolean $manage_apache = true,
) {
  $served = "${binhost_dir.regsubst('/+\z', '')}/"
  $live = "${pkgdir_root.regsubst('/+\z', '')}/"
  if $served.stdlib::start_with($live) or $live.stdlib::start_with($served) {
    fail("portage::buildhost::binhost: binhost_dir ${binhost_dir} overlaps the live PKGDIRs in ${pkgdir_root}")
  }
  if $ssl and ($ssl_cert =~ Undef or $ssl_key =~ Undef) {
    fail('portage::buildhost::binhost: ssl requires ssl_cert and ssl_key')
  }

  if $manage_apache {
    include apache
  }

  $vhost_port = $port ? {
    undef   => $ssl ? { true => 443, default => 80 },
    default => $port,
  }

  $access = $auth_user_file ? {
    undef   => { 'require' => 'all granted' },
    default => {
      'auth_type'      => 'Basic',
      'auth_name'      => $auth_name,
      'auth_user_file' => $auth_user_file,
      'require'        => 'valid-user',
    },
  }

  apache::vhost { "portage-binhost-${vhost_port}":
    servername     => $servername,
    port           => $vhost_port,
    docroot        => $binhost_dir,
    manage_docroot => false,
    ssl            => $ssl,
    ssl_cert       => $ssl_cert,
    ssl_key        => $ssl_key,
    ssl_chain      => $ssl_chain,
    directories    => [
      {
        'path'           => $binhost_dir,
        'options'        => ['-Indexes', '-ExecCGI', '-Includes', '+FollowSymLinks'],
        'allow_override' => ['None'],
      } + $access,
    ],
  }

  if $ssl and $redirect_http and $vhost_port != 80 {
    apache::vhost { 'portage-binhost-80':
      servername      => $servername,
      port            => 80,
      docroot         => $binhost_dir,
      manage_docroot  => false,
      redirect_status => 'permanent',
      redirect_dest   => "https://${servername}/",
    }
  }
}
