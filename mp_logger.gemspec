require_relative 'lib/miracle_plus/logger/version'

Gem::Specification.new do |spec|
  spec.name          = 'mp_logger'
  spec.version       = MiraclePlus::Logger::VERSION
  spec.authors       = ['Hunter']
  spec.email         = ['ttitoo@gmail.com']
  spec.summary       = 'A pluggable gem for MiraclePlus apps'
  spec.description   = ''
  spec.homepage      = 'https://www.miracleplus.com'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = 'https://github.com/MiraclePlus/mp_logger'

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = 'https://github.com/MiraclePlus/mp_logger'

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency 'rails', '~> 7.0'
  spec.add_dependency 'i18n' # https://rubygems.org/gems/i18n
  spec.add_dependency 'hashids' # https://rubygems.org/gems/hashids
  spec.add_dependency 'redis', '~> 4.8'
  spec.add_dependency 'hiredis', '~> 0.6.3' # https://rubygems.org/gems/hiredis

  spec.add_dependency 'ougai' # https://rubygems.org/gems/ougai
  spec.add_dependency 'request_store' # https://github.com/steveklabnik/request_store
  # spec.add_dependency 'enterprise_script_service', '~> 0.2.1'
  spec.add_dependency 'msgpack'
  spec.add_dependency 'parser'
end
