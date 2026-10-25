# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Useflag', type: :type_alias do
  it { is_expected.to allow_values('ssl', '-ssl', 'gtk+', 'python_targets_python3_11', 'abi_x86_32') }
  it { is_expected.not_to allow_values('', '-', 'ssl flag', '--ssl', '+ssl', 'a;b', 3) }
end
