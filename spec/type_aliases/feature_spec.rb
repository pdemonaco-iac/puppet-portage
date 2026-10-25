# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Feature', type: :type_alias do
  it { is_expected.to allow_values('sandbox', '-sandbox', 'buildpkg', 'binpkg-multi-instance', '-*', 'test', 'xattr') }
  it { is_expected.not_to allow_values('', 'bogus', '-', '--sandbox', 'sandbox buildpkg', 'SANDBOX', 3) }
end
