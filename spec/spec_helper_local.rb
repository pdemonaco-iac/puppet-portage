# frozen_string_literal: true

# Fail the suite when resource coverage drops below COVERAGE_MIN (percent).
# Opt-in so that running a single spec file does not trip the threshold; CI
# sets it for the full-suite coverage job.
module PortageCoverageMinimum
  def report!(coverage_desired = nil)
    super(coverage_desired || Float(ENV.fetch('COVERAGE_MIN', 0)))
  end
end

RSpec::Puppet::Coverage.prepend(PortageCoverageMinimum)
