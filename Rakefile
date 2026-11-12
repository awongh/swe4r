# frozen_string_literal: true

require 'rake/testtask'

desc 'Compile the native extension in this checkout'
task :compile do
  Dir.chdir('ext/swe4r') do
    ruby 'extconf.rb'
    sh ENV.fetch('MAKE', 'make')
  end
end

Rake::TestTask.new do |t|
  t.libs += %w[ext test]
end

task test: :compile

desc 'Build an isolated AddressSanitizer extension and run all tests'
task :asan do
  ruby 'script/test_asan.rb'
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
