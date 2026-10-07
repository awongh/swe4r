# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc 'Run tests'
task default: :test

desc 'build and install locally'
task :install do
  puts 'uninstalling'
  `gem uninstall swe4r`
  puts 'building'
  `gem build swe4r.gemspec`
  gemfile = Dir['swe4r-*.gem'].max
  raise 'no swe4r-*.gem built' unless gemfile

  `gem install --local ./#{gemfile}`
  puts 'done!'
end
