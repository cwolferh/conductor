Factory.define :provider do |p|
  p.sequence(:name) { |n| "provider#{n}" }
  p.provider_type { ProviderType.find_by_codename("mock") }
  p.url { |p| "http://www." + p.name + ".com/api" }
end

Factory.define :mock_provider, :parent => :provider do |p|
  p.provider_type { ProviderType.find_by_codename("mock") }
  p.url 'http://localhost:3001/api'
  p.hardware_profiles { |hp| [hp.association(:mock_hwp1), hp.association(:mock_hwp2)] }
  p.after_create { |p| p.realms << Factory(:realm1, :provider => p) << Factory(:realm2, :provider => p) }
end

Factory.define :mock_provider2, :parent => :provider do |p|
  p.name 'mock2'
  p.provider_type { ProviderType.find_by_codename("mock") }
  p.url 'http://localhost:3001/api'
  p.after_create { |p| p.realms << Factory(:realm3, :provider => p) }
end

Factory.define :ec2_provider, :parent => :provider do |p|
  p.name 'amazon-ec2'
  p.provider_type { ProviderType.find_by_codename("ec2") }
  p.url 'http://localhost:3001/api'
  p.hardware_profiles { |hp| [hp.association(:ec2_hwp1)] }
  p.after_create { |p| p.realms << Factory(:realm4, :provider => p) }
end

Factory.define :ec2_provider_no_builds, :parent => :provider do |p|
  p.name 'amazon-ec2-no-builds'
  p.provider_type { ProviderType.find_by_codename("ec2") }
  p.url 'http://localhost:3002/api'
  p.hardware_profiles { |hp| [hp.association(:ec2_hwp1)] }
  p.after_create { |p| p.realms << Factory(:realm4, :provider => p) }
end
