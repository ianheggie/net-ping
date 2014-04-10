#!/usr/bin/env ruby

if RUBY_VERSION !~ /^1\.8/ && (ENV['TRAVIS'] || ENV['APPVEYOR'])
  require 'coveralls'
  Coveralls.wear!
end

require 'test-unit'

LOCALHOST = 'localhost'
BOGUS_HOST = 'foo.bar.baz'

LOCALHOST_IP = '127.0.0.1'
DEFAULT_BLACKHOLE_IP = '144.140.108.23' # telstra.com - aussie ISP that drops packets
DEFAULT_BLACKHOLE_PORT = 1001

if defined? SimpleCov
  SimpleCov.start :rails do
    filters.clear # This will remove the :root_filter that comes via simplecov's defaults
    add_filter do |src|
      !(src.filename =~ /^#{SimpleCov.root}/) unless src.filename =~ %r{lib/net/ping2}
    end
  end
end

module TestHelper

  def local_tcp_port
    (ENV['LOCAL_TCP_PORT'] || 22).to_i
  end

  # ---------------------------
  # Helpers to add tests

  def check_ping_arguments

    %w{ping ping?}.each do |method|

      define_method "test_#{method}_without_arguments_or_default_host_raises_exception" do
        #noinspection RubyArgCount
        assert_raise(ArgumentError) { @ping.ping }
      end

      define_method "test_#{method}_without_arguments_but_with_default_host" do
        assert_nothing_raised { @ping_with_host.ping }
      end

      define_method "test_#{method}_accepts_a_hostname" do
        assert_nothing_raised { @ping.ping(LOCALHOST_IP) }
      end
    end

  end

  def check_class_methods(*methods)
    # Class methods
    %w{not_available_message available?}.concat(methods).each do |method|
      define_method "test_has_#{method}_class_method" do
        assert_respond_to(Net::Ping2::Base, method)
      end
    end
  end

  def check_attr_readers(*methods)
    %w{exception duration ping ping? response warning success success?}.concat(methods).each do |method|
      define_method "test_has_#{method}_method" do
        assert_respond_to(@ping, method)
      end
    end
  end

  def check_attr_accessors(*methods)
    methods = %w{timeout}.concat(methods)
    methods.each do |method|
      define_method "test_has_#{method}_method" do
        assert_respond_to(@ping, method)
      end
      setter = "#{method}="
      define_method "test_has_working_#{setter}_method" do
        assert_respond_to(@ping, setter)
        @ping.send(setter, 42)
        assert_equal(42, @ping.send(method))
      end
    end
  end

  def check_defaults(method_defaults = {})
    {:duration => nil,
     :exception => nil,
     :response => nil,
     :warning => nil
    }.merge(method_defaults).each do |method, value|
      if method
        define_method "test_#{method}_defaults_to_#{value.inspect}" do
          assert_equal(value, @ping.send(method), "#{method} default")
        end
      end
    end
  end

  def check_good_host_behaviour(should_be_set = [], should_be_nil = [])
    define_method "test_pinging_a_good_host_returns_true_and_sets_attributes_accordingly" do
      assert_true(@ping.ping?(LOCALHOST_IP), 'ping?(LOCALHOST_IP) should be true, exception = %s, response=%s' % [@ping.exception, @ping.response])
      assert_true(@ping.success?, 'success? should be true')
      ['duration', 'response', 'success', should_be_set].flatten.each do |method|
        assert_not_nil(@ping.send(method), "#{method} should be set on success") if method
      end
      ['exception', should_be_nil].flatten.each do |method|
        assert_nil(@ping.send(method), "#{method} should be nil on success") if method
      end
      assert_kind_of(Float, @ping.duration, 'duration should be a float on success')
    end
  end

  def check_bad_hosts_behaviour(bad_host_name_list, should_be_set = [], should_be_nil = [])
    klass = self
    bad_host_name_list.each do |name, host|
      define_method "test_pinging_#{name}_returns_false_and_sets_attributes_accordingly" do
        @ping.timeout = 2
        @ping.port = klass.blackhole_port if @ping.respond_to? :port=
        started = Time.now
        @result = @ping.ping?(host)
        @duration = Time.now - started
        assert_false(@result, "ping?(#{host}) should be false, exception = #{@ping.exception}, response = #{@ping.response}")
        assert_false(@ping.success?)
        ['exception', 'success', should_be_set].flatten.each do |method|
          assert_not_nil(@ping.send(method), "#{method} should be set on failure") if method
        end
        ['duration', should_be_nil].flatten.each do |method|
          assert_nil(@ping.send(method), "#{method} should be nil on failure") if method
        end
        assert_true(@duration < 3.9, "pinging #{name} should take < 3.9 seconds, actually took #{@duration}")
      end
    end
  end

  def check_good_service_check(options={})
    define_method "test_pinging_a_good_service_returns_true_and_sets_attributes_accordingly" do
      assert_respond_to(@ping, :service_check)
      @ping.service_check = true
      assert_true(@ping.ping?(LOCALHOST_IP, options), 'ping?(LOCALHOST_IP) should be true, exception = %s, response=%s' % [@ping.exception, @ping.response])
      assert_true(@ping.success?, 'success? should be true')
      ['duration', 'response', 'success'].flatten.each do |method|
        assert_not_nil(@ping.send(method), "#{method} should be set on success") if method
      end
      ['exception'].flatten.each do |method|
        assert_nil(@ping.send(method), "#{method} should be nil on success") if method
      end
      assert_kind_of(Float, @ping.duration, 'duration should be a float on success')
    end
  end

  def check_bad_service_check(options={})
    klass = self
    define_method "test_pinging_a_bad_service_returns_false_and_sets_attributes_accordingly" do
      assert_respond_to(@ping, :service_check)
      @ping.service_check = true
      @ping.timeout = 2
      @ping.port = klass.blackhole_port
      started = Time.now
      @result = @ping.ping?(LOCALHOST_IP)
      @duration = Time.now - started
      assert_false(@result, "ping?(bad_service) should be false, exception = #{@ping.exception}, response = #{@ping.response}")
      assert_false(@ping.success?)
      ['exception', 'success'].flatten.each do |method|
        assert_not_nil(@ping.send(method), "#{method} should be set on failure") if method
      end
      ['duration'].flatten.each do |method|
        assert_nil(@ping.send(method), "#{method} should be nil on failure") if method
      end
      assert_true(@duration < 3.9, "pinging bad_service should take < 3.9 seconds, actually took #{@duration}")
    end
  end

  def ping_hosts_sequentially(hosts, klass)
    hosts.collect do |ip|
      p = klass.new(:host => ip, :timeout => 2)
      [ip, p.ping?(ip)]
    end
  end

  def ping_hosts_in_parallel(hosts, klass)
    threads = hosts.collect do |ip|
      Thread.new(ip) do |thread_ip|
        p = klass.new(:host => thread_ip, :timeout => 2)
        [thread_ip, p.ping?(thread_ip)]
      end
    end
    threads.collect do |t|
      t.value
    end
  end

  def check_thread_safety
    klass = self
    define_method 'test_multiple_threads_return_same_value_as_sequential_checks' do
      hosts = ['8.8.4.4', '8.8.9.9', '127.0.0.1', '8.8.8.8', '8.8.8.9']
      sequentially = klass.ping_hosts_sequentially(hosts, @ping.class)
      in_parallel = klass.ping_hosts_in_parallel(hosts, @ping.class)
      assert_equal(sequentially, in_parallel, "#{@ping.class} Should work the same in threads")
      assert_equal(hosts.size, sequentially.size, "#{@ping.class} sequential should have results for all the hosts")
    end
  end


# ------------------------------------------
# common definitions


  def bad_hostname
    'no.such.domain.exists'
  end

  def bad_hostname_uri
    'http://%s' % self.bad_hostname
  end

  def unreachable_host
    ENV['UNREACHABLE_HOST'] != '' && ENV['UNREACHABLE_HOST']
  end

  def unreachable_route
    ENV['UNREACHABLE_ROUTE'] != '' && ENV['UNREACHABLE_ROUTE']
  end

  def blackhole_ip
    if ENV['BLACKHOLE_IP'].to_s =~ /(\S+)/
      $1
    else
      DEFAULT_BLACKHOLE_IP
    end
  end

  def blackhole_port
    if ENV['BLACKHOLE_PORT'].to_s =~ /(\d+)/
      $1.to_i
    else
      DEFAULT_BLACKHOLE_PORT
    end
  end

  def unreachable_host_uri
    'http://%s:%d/' % [TestHelper.unreachable_host, TestHelper.blackhole_port] if TestHelper.unreachable_host
  end

  def unreachable_route_uri
    'http://%s:%d/' % [TestHelper.unreachable_route, TestHelper.blackhole_port] if TestHelper.unreachable_route
  end

  def blackhole_uri
    'http://%s:%d/' % [TestHelper.blackhole_ip, TestHelper.blackhole_port] if TestHelper.blackhole_ip
  end

  def allow_net_connect
    res = '127.0.0.1'
    bad_hosts.each do |name, host, port|
      res << '|' << host if host != self.bad_hostname
    end
    %r[^https?://(#{res.gsub('.', '\.')})]
  end

  def bad_hosts
    port = self.blackhole_port
    res = [['bogus_hostname', self.bad_hostname, port]]
    res << ['unreachable_host', self.unreachable_host, port] if self.unreachable_host
    res << ['unreachable_route', self.unreachable_route, port] if self.unreachable_route
    res << ['blackhole_ip', self.blackhole_ip, port] if self.blackhole_ip
    res
  end

  def bad_uris
    self.bad_hosts.collect { |name, host, port| [name, 'http://%s:%d/' % [host, port]] }
  end

end

# class TestTestHelperClass < Test::Unit::TestCase
#   extend TestHelper
# end
#
# @helper = TestTestHelperClass.new

class Test::Unit::TestCase
  extend TestHelper
end
