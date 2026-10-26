# frozen_string_literal: true

require 'spec_helper'

describe 'portage::buildhost::binhost' do
  let(:facts) do
    {
      os: { name: 'Gentoo', family: 'Gentoo', architecture: 'amd64', hardware: 'x86_64', release: { full: 'rolling', major: 'rolling' } },
      kernel: 'Linux',
      networking: { fqdn: 'buildhost.example.org', hostname: 'buildhost', domain: 'example.org', ip: '192.0.2.10' },
    }
  end

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_class('apache') }

  it do
    is_expected.to contain_apache__vhost('portage-binhost-80').with(
      servername: 'buildhost.example.org',
      port: 80,
      docroot: '/srv/binhost',
      manage_docroot: false,
      ssl: false,
      directories: [{
        'path' => '/srv/binhost',
        'options' => ['-Indexes', '-ExecCGI', '-Includes', '+FollowSymLinks'],
        'allow_override' => ['None'],
        'require' => 'all granted',
      }],
    )
  end

  it 'does not take over the published directory from portage::buildhost::publish' do
    is_expected.not_to contain_file('/srv/binhost')
  end

  it 'never serves the live PKGDIRs' do
    vhosts = catalogue.resources.select { |r| r.type == 'Apache::Vhost' && r.title.start_with?('portage-binhost') }
    expect(vhosts.map { |v| v[:docroot] }).to all(eq('/srv/binhost'))
    expect(vhosts.flat_map { |v| v[:directories].map { |d| d['path'] } }).to all(eq('/srv/binhost'))
  end

  context 'with ssl' do
    let(:params) { { ssl: true, ssl_cert: '/etc/ssl/binhost.crt', ssl_key: '/etc/ssl/binhost.key', ssl_chain: '/etc/ssl/chain.pem' } }

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_apache__vhost('portage-binhost-443').with(
        port: 443, ssl: true, ssl_cert: '/etc/ssl/binhost.crt', ssl_key: '/etc/ssl/binhost.key', ssl_chain: '/etc/ssl/chain.pem',
      )
    end

    it { is_expected.to contain_apache__vhost('portage-binhost-80').with(port: 80, redirect_status: 'permanent', redirect_dest: 'https://buildhost.example.org/') }

    context 'without the redirect' do
      let(:params) { super().merge(redirect_http: false) }

      it { is_expected.not_to contain_apache__vhost('portage-binhost-80') }
    end

    context 'without a key' do
      let(:params) { super().merge(ssl_key: :undef) }

      it { is_expected.to compile.and_raise_error(%r{ssl requires ssl_cert and ssl_key}) }
    end
  end

  context 'with basic auth, a servername and a port' do
    let(:params) { { auth_user_file: '/etc/apache2/binhost.htpasswd', servername: 'binhost.example.org', port: 8080 } }

    it do
      is_expected.to contain_apache__vhost('portage-binhost-8080').with(
        servername: 'binhost.example.org',
        port: 8080,
        directories: [{
          'path' => '/srv/binhost',
          'options' => ['-Indexes', '-ExecCGI', '-Includes', '+FollowSymLinks'],
          'allow_override' => ['None'],
          'auth_type' => 'Basic',
          'auth_name' => 'Portage binhost',
          'auth_user_file' => '/etc/apache2/binhost.htpasswd',
          'require' => 'valid-user',
        }],
      )
    end
  end

  context 'with the host target' do
    let(:pre_condition) { 'include portage' }

    it { is_expected.to compile.with_all_deps }

    it 'gets apache\'s Gentoo build settings into the host make.conf through the shim' do
      is_expected.to contain_portage__makeconf('apache2_mpms').with_content('prefork')
      is_expected.to contain_file('/etc/portage/make.conf').with_content(%r{^APACHE2_MPMS="prefork"$})
    end
  end

  context 'without managing apache' do
    let(:params) { { manage_apache: false } }
    let(:pre_condition) { "class { 'apache': default_vhost => false }" }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_apache__vhost('portage-binhost-80') }
  end

  ['/var/cache/portage-targets', '/var/cache/portage-targets/desktop', '/var/cache', '/'].each do |dir|
    context "with binhost_dir #{dir}" do
      let(:params) { { binhost_dir: dir } }

      it { is_expected.to compile.and_raise_error(%r{overlaps the live PKGDIRs}) }
    end
  end
end
