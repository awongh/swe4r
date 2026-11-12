# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'rbconfig'
require 'shellwords'
require 'tmpdir'

root = File.expand_path('..', __dir__)
compiler = Shellwords.split(ENV.fetch('CC', RbConfig::CONFIG.fetch('CC')))
if RbConfig::CONFIG.fetch('host_os').include?('darwin')
  runtime_name = 'libclang_rt.asan_osx_dynamic.dylib'
  preload_key = 'DYLD_INSERT_LIBRARIES'
else
  runtime_name = "libclang_rt.asan-#{RbConfig::CONFIG.fetch('host_cpu')}.so"
  preload_key = 'LD_PRELOAD'
end
runtime, status = Open3.capture2(*compiler, "-print-file-name=#{runtime_name}")
runtime = runtime.strip
unless status.success? && File.file?(runtime)
  runtime, status = Open3.capture2(*compiler, '-print-file-name=libasan.so')
  runtime = runtime.strip
end
unless status.success? && File.file?(runtime)
  abort 'AddressSanitizer runtime not found; set CC to a compiler with ASan support'
end

Dir.mktmpdir('swe4r-asan-') do |dir|
  FileUtils.mkdir_p(File.join(dir, 'ext/swe4r'))
  FileUtils.cp_r(File.join(root, 'lib'), dir)
  FileUtils.cp_r(File.join(root, 'test'), dir)
  FileUtils.cp(Dir[File.join(root, 'ext/swe4r/*.{c,h,rb}')], File.join(dir, 'ext/swe4r'))
  Dir.chdir(File.join(dir, 'ext/swe4r')) do
    system(RbConfig.ruby, 'extconf.rb', '--with-cflags=-O1 -g -fsanitize=address -fno-omit-frame-pointer',
           '--with-ldflags=-fsanitize=address', exception: true)
    system(ENV.fetch('MAKE', 'make'), "CC=#{compiler.shelljoin}", exception: true)
  end
  preload = [runtime, ENV.fetch(preload_key, nil)].compact.reject(&:empty?).join(':')
  env = { preload_key => preload, 'ASAN_OPTIONS' => ENV.fetch('ASAN_OPTIONS', 'detect_leaks=0'),
          'SWE4R_ASAN_PRELOAD_KEY' => preload_key, 'SWE4R_ASAN_RUNTIME' => preload }
  Dir.chdir(dir) do
    system(env, RbConfig.ruby, '-Ilib', '-Iext', '-Itest', '-e',
           'Dir["test/test*.rb"].sort.each { |file| require_relative file }', exception: true)
  end
end
