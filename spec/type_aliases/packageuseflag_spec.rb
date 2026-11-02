# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Packageuseflag', type: :type_alias do
  it { is_expected.to allow_values('ssl', '-ssl', '-*', 'PYTHON_TARGETS:', 'VIDEO_CARDS:', 'CPU_FLAGS_X86:') }
  it { is_expected.not_to allow_values('', ':', 'python_targets:', 'PYTHON_TARGETS', 'PYTHON TARGETS:', '*', 3) }
end
