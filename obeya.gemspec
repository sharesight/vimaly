# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'obeya/version'

Gem::Specification.new do |spec|
  spec.name          = "obeya"
  spec.version       = Obeya::VERSION
  spec.authors       = ["Thorsten Boettger"]
  spec.email         = ["boettger@mt7.de"]

  spec.summary       = %q{Wrapper for the Obeya API}
  spec.description   = %q{Wrapper for the Obeya API}
  spec.homepage      = "https://github.com/sharesight/obeya"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday"
  spec.add_dependency "faraday_middleware"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "maxitest", '~> 1'
  spec.add_development_dependency "shoulda-context"
  spec.add_development_dependency "webmock"
end
