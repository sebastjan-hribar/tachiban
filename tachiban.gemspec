# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tachiban/version'

Gem::Specification.new do |spec|
  spec.name          = "tachiban"
  spec.version       = Tachiban::VERSION
  spec.authors       = ["Sebastjan Hribar"]
  spec.email         = ["sebastjan.hribar@gmail.com"]

  spec.summary       = %q{Tachiban provides simple password hashing for user authentication with bcrypt for Hanami web applications.}
  spec.homepage      = "https://github.com/sebastjan-hribar/tachiban"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ["tachiban"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "hanami-model", "~> 1.0"
  spec.add_development_dependency "timecop", "0.8.1"
  spec.add_development_dependency 'hanami-controller', "~> 1.0"
  spec.add_development_dependency 'hanami-router', "~> 1.0"
  spec.add_development_dependency 'pry'

  spec.add_runtime_dependency "bcrypt", "~> 3.1"
  spec.add_runtime_dependency 'hanami-controller', "~> 1.0"
  spec.add_runtime_dependency 'hanami-router', "~> 1.0"
end
