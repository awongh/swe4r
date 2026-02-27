# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name              = 'swe4r'
  s.version           = '1.1.7'
  s.summary           = 'Swiss Ephemeris for Ruby'
  s.description       = 'A C extension for the Swiss Ephemeris library (http://www.astro.com/swisseph/)'
  s.homepage          = 'https://github.com/dfl/swe4r'
  s.author            = 'David Lowenfels'
  s.email             = 'dfl@alum.mit.edu'
  s.license           = 'GPL-2.0'
  s.required_ruby_version = '>= 3.2.0'
  s.extra_rdoc_files  = ['README.rdoc']
  s.files             = Dir.glob('lib/**/*.{rb}') + Dir.glob('ext/**/*.{rb,h,c}')
  s.extensions        = ['ext/swe4r/extconf.rb']

  s.metadata['rubygems_mfa_required'] = 'true'
end
