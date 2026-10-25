# frozen_string_literal: true

require 'spec_helper'

describe 'portage' do
  # FacterDB has no Gentoo fact sets, so on_supported_os would yield no examples.
  let(:facts) do
    {
      os: {
        name: 'Gentoo',
        family: 'Gentoo',
        architecture: 'amd64',
        hardware: 'x86_64',
        release: { full: 'rolling', major: 'rolling' },
      },
      kernel: 'Linux',
    }
  end

  it { is_expected.to compile.with_all_deps }
end
