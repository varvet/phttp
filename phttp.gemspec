# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'phttp/version'

Gem::Specification.new do |spec|
  spec.name          = "phttp"
  spec.version       = PHTTP::VERSION
  spec.authors       = ["Kim Burgestrand", "Elabs"]
  spec.email         = ["kim@burgestrand.se", "dev@elabs.se"]
  spec.summary       = "Parallell HTTP requests."
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "http"
  spec.add_dependency "nio4r"
  spec.add_development_dependency "rack"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
end
