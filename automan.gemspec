# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'automan/version'

Gem::Specification.new do |spec|
  spec.name          = "automan"
  spec.version       = Automan::VERSION
  spec.authors       = ["Chris Chalfant"]
  spec.email         = ["cchalfant@leafsoftwaresolutions.com"]
  spec.description   = %q{Automanes common AWS ops}
  spec.summary       = %q{Automanes common AWS ops}
  spec.homepage      = ""

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-core", "~> 2.12.2"
  spec.add_development_dependency "rspec-mocks", "~> 2.12.2"
  spec.add_development_dependency "rspec-expectations", "~> 2.12.1"
  spec.add_dependency "aws-sdk"
  spec.add_dependency "thor"
  spec.add_dependency "json"
  spec.add_dependency "wait"
  spec.add_dependency "minitar"
end
