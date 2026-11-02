# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Licensetoken', type: :type_alias do
  it { is_expected.to allow_values('GPL-2', '-Artistic', '@FREE', '-@EULA', '*', '-*', 'linux-fw-redistributable') }
  it { is_expected.not_to allow_values('', '-', '@', 'bad license', '--GPL-2', 3) }
end
