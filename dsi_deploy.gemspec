# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dsi_deploy/version'

Gem::Specification.new do |spec|
  spec.name          = "dsi_deploy"
  spec.version       = DSI::Deploy::VERSION
  spec.authors       = ["Ruy Asan"]
  spec.email         = ["ruyasan@gmail.com"]
  spec.summary       = %q{Shared deployment orchestration between puppet and capistrano.}
  spec.description   = %q{Internal tooling}
  spec.homepage      = "http://github.com/deversus/dsi_deploy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake", "~> 10.3"
  spec.add_runtime_dependency "hiera" , "~> 1.3"
end
