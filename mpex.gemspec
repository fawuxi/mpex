# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mpex/version"

Gem::Specification.new do |s|
  s.name        = "mpex"
  s.version     = Mpex::VERSION
  s.authors     = ["Fa Wuxi"]
  s.email       = [""]
  s.homepage    = "https://github.com/fawuxi/mpex"
  s.summary     = %q{MPEx.rb: a commandline client for MPEx}
  s.description = %q{MPEx.rb is a commandline client for "MPEx":http://mpex.co a Bitcoin security exchange. Make sure to carefully read its "FAQ":http://mpex.co/faq.html before using it.}

  s.files         = Dir['[A-Z]*'] + Dir['{bin,lib,tasks,test}/**/*'] + [ 'mpex.gemspec' ]
  s.extra_rdoc_files = ['README.md']
  s.rdoc_options  = [ '--main', 'README.md' ]
  s.executables   = [ 'mpex' ]
  s.require_paths = [ 'lib' ]

  s.add_runtime_dependency "cri", '~> 2.2'
  s.add_runtime_dependency "json"
  s.add_runtime_dependency "highline"
  s.add_runtime_dependency "gpgme"
  s.add_runtime_dependency "net-yail"

  s.add_development_dependency "rake"
  s.add_development_dependency "cucumber"
  s.add_development_dependency "rspec-expectations"

  s.post_install_message = %q{------------------------------------------------------------------------------
run "mpex help" for usage information; or "mpex -i" to start interactive
------------------------------------------------------------------------------
}
end
