# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Atom', type: :type_alias do
  it { is_expected.to allow_values('sys-apps/sed', '>media-libs/libgd-1.6', 'sys-libs/zlib-1.1.4-r', 'net-misc/dhcp-3.0_p2', '>=dev-lang/ruby-3.2:3.2', '=dev-libs/foo-1.2*', '!!app-misc/bar', 'dev-libs/baz::gentoo', 'dev-libs/baz:0/1.2=', '~sys-apps/sed-4.8') }
  it { is_expected.not_to allow_values('', 'sed', 'sys-apps/', '>sys-apps/sed', 'sys apps/sed', 'sys-apps/sed;rm', '=sys-apps/sed', '/etc/passwd', 'sys-apps/sed::', 3) }
end
