# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/emerge/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-emerge'
  spec.version       = Fastlane::Emerge::VERSION
  spec.author        = 'Emerge Tools, Inc'

  spec.summary       = 'Fastlane plugin for Emerge'
  spec.homepage      = "https://github.com/EmergeTools/fastlane-plugin-emerge"
  spec.license       = "MIT"
  spec.required_ruby_version = '>= 3.0'

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  spec.add_dependency('faraday', '~> 2.14', '>= 2.14.1')

  spec.add_development_dependency('pry')
  spec.add_development_dependency('bundler')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rspec_junit_formatter')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rubocop', '~> 1.90.0')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('simplecov', '~> 0.22.0')
  spec.add_development_dependency('fastlane', '>= 2.170.0')
end
