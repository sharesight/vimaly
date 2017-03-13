# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vimaly/version'

Gem::Specification.new do |spec|
  spec.name          = "vimaly"
  spec.version       = Vimaly::VERSION
  spec.authors       = ["Thorsten Boettger"]
  spec.email         = ["boettger@mt7.de"]

  spec.summary       = %q{Wrapper for the Vimaly API}
  spec.description   = %q{Wrapper for the Vimaly API}
  spec.homepage      = "https://github.com/sharesight/vimaly"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday"
  spec.add_dependency "faraday_middleware"
  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "maxitest", '~> 1'
  spec.add_development_dependency "shoulda-context"
  spec.add_development_dependency "webmock"
end
