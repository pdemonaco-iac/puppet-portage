# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Useexpandflag', type: :type_alias do
  it { is_expected.to allow_values('amdgpu', '-*', 'efi-64', 'python3_13', '-python3_14') }
  it { is_expected.not_to allow_values('', '*', '-**', 'PYTHON_TARGETS:', 'a b', 3) }
end
