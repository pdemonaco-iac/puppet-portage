# frozen_string_literal: true

require 'spec_helper'

describe 'portage::makeconf' do
  let(:title) { 'apache2_mpms' }
  let(:params) { { content: 'prefork' } }

  it { is_expected.to compile.with_all_deps }
  it { is_expected.to contain_portage__makeconf('apache2_mpms').with(content: 'prefork', variable: 'apache2_mpms') }

  it 'declares nothing itself' do
    expect(catalogue.resources.map(&:type)).not_to include('File', 'Exec')
  end

  context 'with apache2_modules as an array' do
    let(:title) { 'apache2_modules' }
    let(:params) { { content: %w[alias authz_core dir] } }

    it { is_expected.to compile.with_all_deps }
  end

  context 'without content' do
    let(:params) { {} }

    it { is_expected.to compile.and_raise_error(%r{content}) }
  end

  context 'with a variable the host target does not pick up' do
    let(:title) { 'video_cards' }

    it { is_expected.to compile.and_raise_error(%r{variable}) }
  end
end
