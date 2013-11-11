# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'phttp/version'

Gem::Specification.new do |spec|
  spec.name          = "phttp"
  spec.version       = Phttp::VERSION
  spec.authors       = ["Kim Burgestrand", "Jonas Nicklas"]
  spec.email         = ["kim@burgestrand.se", "jonas.nicklas@gmail.com"]
  spec.summary       = "Promising Typhoeus HTTP requests."
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "typhoeus"
  spec.add_development_dependency "rspec", "~> 2.0"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end