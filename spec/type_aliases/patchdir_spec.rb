# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Patchdir', type: :type_alias do
  it { is_expected.to allow_values('sys-apps/sed', 'sys-apps/sed-4.8', 'sys-apps/sed-4.8-r1', 'sys-apps/sed:0', 'dev-lang/ruby-3.3.1_p5:3.3', 'net-misc/dhcp-3.0_p2') }
  it { is_expected.not_to allow_values('', 'sed', 'sys-apps/', '>=sys-apps/sed-4.8', 'sys-apps/sed/extra', 'sys-apps/sed::gentoo', '../etc/passwd', 'sys apps/sed', 3) }
end
