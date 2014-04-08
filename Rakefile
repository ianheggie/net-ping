require "bundler/gem_tasks"

require 'rake'
require 'rake/clean'
require 'rake/testtask'

namespace 'example' do
  %w{external http tcp udp}.each do |protocol|
    desc "Run the #{protocol} ping example program"
    task protocol do
       ruby "-Ilib examples/example_ping#{protocol}.rb"
    end
  end
end

Rake::TestTask.new do |t|
   #t.libs << 'test'
   t.warning = true
   t.verbose = true

   list = ['test/test_net_ping*.rb', 'examples/example_ping*.rb']

   t.test_files = FileList.new(list)
end

namespace 'test' do
  %w{external http icmp tcp udp wmi base}.each do |protocol|
    Rake::TestTask.new(protocol) do |t|
       t.warning = true
       t.verbose = true
       t.test_files = FileList['test/test_net_ping2_%s.rb' % protocol]
    end
  end
end

task :default => :test
