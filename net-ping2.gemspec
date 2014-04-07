# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'net/ping2/version'

Gem::Specification.new do |spec|
  spec.name          = 'net-ping2'
  spec.version       = Net::Ping2::VERSION
  spec.authors       = ['Daniel J. Berger', 'Ian Heggie']
  spec.email         = ['djberg96@gmail.com', 'ian@heggie.biz']
  spec.summary       = %q{Check a remote host for reachability, with optional service check}
  spec.description   = %q{This gem provides a collection of classes that provide different ways to ping computers,
                          specifically: external command, http (default), icmp (requires root / administrator rights),
                          tcp, udp, wmi (Windows only). }
  spec.homepage      = 'https://github.com/ianheggie/net-ping'
  spec.license       = 'Artistic 2.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.extra_rdoc_files  = ['README.md', 'CHANGES.txt', 'doc/net-ping2.md']

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency 'test-unit'
  spec.add_development_dependency 'fakeweb'

  spec.required_ruby_version = ">= 1.8.7"

  if File::ALT_SEPARATOR
    require 'rbconfig'
    arch = RbConfig::CONFIG['build_os']
    spec.platform = Gem::Platform.new(['universal', arch])
    spec.platform.version = nil

    # Used for icmp pings.
    spec.add_dependency('win32-security', '>= 0.2.0')
  end

end
