# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'benevolent_gaze/version'

Gem::Specification.new do |spec|
  spec.name          = "benevolent_gaze"
  spec.version       = BenevolentGaze::VERSION
  spec.authors       = ["Will Schenk"]
  spec.email         = ["wschenk@gmail.com"]
  spec.summary       = %q{See your coworkers.}
  spec.description   = %q{See your coworkers.  Totally not creepy.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra"
  spec.add_dependency "redis"
  spec.add_dependency "sinatra-support"
  spec.add_dependency "sinatra-contrib"
  spec.add_dependency "thin"
  spec.add_dependency "json"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
