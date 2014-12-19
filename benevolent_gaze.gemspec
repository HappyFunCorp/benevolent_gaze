# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'benevolent_gaze/version'

Gem::Specification.new do |spec|
  spec.name          = "benevolent_gaze"
  spec.version       = BenevolentGaze::VERSION
  spec.authors       = ["Will Schenk", "Aaron Brocken"]
  spec.email         = ["wschenk@gmail.com", "aaron@happyfuncorp.com"]
  spec.summary       = %q{See your coworkers.}
  spec.description   = %q{See your coworkers.  Totally not creepy.}
  spec.homepage      = "http://gaze.happyfuncorp.com/"
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
  spec.add_dependency "httparty"
  spec.add_dependency "sinatra-cross_origin", "~> 0.3.1"
  spec.add_dependency "aws-s3"
  spec.add_dependency "mini_magick"
  spec.add_dependency "thor"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
