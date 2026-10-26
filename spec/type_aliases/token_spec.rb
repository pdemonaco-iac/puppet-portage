# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Token', type: :type_alias do
  it { is_expected.to allow_values('*.pyc', '/etc/foo', 'gif') }
  it { is_expected.not_to allow_values('', 'a b', 'a"b', 3) }
end
