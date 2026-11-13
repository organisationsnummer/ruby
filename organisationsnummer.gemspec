# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
    s.name        = 'organisationsnummer'
    s.version     = '1.0.0'
    s.date        = '2026-11-13'
    s.summary     = 'Validate Swedish organization numbers'
    s.description = 'Validate Swedish organization numbers'
    s.authors     = ['Rasmus Graham']
    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    s.require_paths = ["lib"]
    s.homepage    = 'https://github.com/organisationsnummer/ruby'
    s.license     = 'MIT'
    s.metadata    = { 'source_code_uri' => 'https://github.com/organisationsnummer/ruby' }
    # The oldest Ruby in the CI matrix.
    s.required_ruby_version = '>= 3.3'
    s.add_runtime_dependency 'personnummer', '~> 3.1', '>= 3.1.1'
    s.add_development_dependency 'rake'
    s.add_development_dependency 'minitest'
  end
