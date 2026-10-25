# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Keyword', type: :type_alias do
  it { is_expected.to allow_values('amd64', '~amd64', '-amd64', '*', '~*', '-*', '**', 'amd64-linux') }
  it { is_expected.not_to allow_values('', '~', '~~amd64', 'AMD64', 'amd64 x86', '-', 3) }
end
