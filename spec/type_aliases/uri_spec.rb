# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Uri', type: :type_alias do
  it { is_expected.to allow_values('https://example.org/gentoo', 'rsync://m.example/gentoo', 'ftp://m.example/x', '/mnt/mirror') }
  it { is_expected.not_to allow_values('', 'example.org', 'gopher://x', 'https://a b', 'https://x"', 3) }
end
