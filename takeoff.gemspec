$:.unshift File.expand_path("../lib", __FILE__)
require "takeoff/version"

Gem::Specification.new do |spec|
  spec.name           = "takeoff"
  spec.version        = Takeoff::VERSION
  spec.author         = "Douwe Maan"
  spec.email          = "douwe@selenight.nl"
  spec.summary        = "Sit back, relax and let Takeoff deploy your app."
  spec.description    = "Takeoff is a command line tool that helps you deploy your web applications. Configure it once, and from then on Takeoff will take care of responsibly deploying your app, giving you time to get more coffee."
  spec.homepage       = "https://github.com/DouweM/takeoff"
  spec.license        = "MIT"
  
  spec.files          = `git ls-files -z`.split("\x0")
  spec.executables    = ["takeoff"]
  spec.require_paths  = ["lib"]
  
  spec.add_dependency "activesupport"
  spec.add_dependency "middleware"
  spec.add_dependency "thor"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end