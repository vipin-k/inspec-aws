# frozen_string_literal: true

# copyright: 2018, The Authors

title 'Sample Section'

# Plural resources can be inspected to check for specific resource details
describe aws_ec2_instance('i-01a2349e94458a507') do
  it { should exist }
end

describe aws_ec2_instance(name: 'my-instance') do
  it { should exist }
end
