# frozen_string_literal: true

require 'spec_helper'

describe 'Portage::Targetroot', type: :type_alias do
  it { is_expected.to allow_values('/', '/var/lib/portage-targets/stage3', '/var/lib/portage-targets/a_b-1.2') }
  it { is_expected.not_to allow_values('', 'etc', '/etc', '//', '/var/lib/portage-targets', '/var/lib/portage-targets/', '/var/lib/portage-targets/a/b', '/var/lib/portage-targets/../etc', '/var/lib/portage-targets-x/a', 3) }
end
