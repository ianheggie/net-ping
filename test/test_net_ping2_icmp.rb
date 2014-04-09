#######################################################################
# test_net_ping_icmp.rb
#
# Test case for the Net::PingICMP class. You must run this test case
# with root privileges on UNIX systems. This should be run via the
# 'test' or 'test:icmp' Rake task.
#######################################################################
require File.expand_path('../test_helper.rb', __FILE__)
require 'net/ping2/icmp'
require 'thread'

class TestNetPing2ICMP < Test::Unit::TestCase

  if Net::Ping2::ICMP.available?

    def setup
      # @host = '127.0.0.1' # 'localhost'
      # @icmp = Net::Ping2::ICMP.new(@host)
      # @blackhole = Net::Ping2::ICMP.new(TestHelper.blackhole_ip)
      # if ENV['EXCLUDE'].to_s =~ /ICMP_ENETUNREACH_BUG/
      #   @unreachable_host = @unreachable_route = nil
      # else
      #   @unreachable_host = TestHelper.unreachable_host && Net::Ping2::ICMP.new(TestHelper.unreachable_host)
      #   @unreachable_route = TestHelper.unreachable_route && Net::Ping2::ICMP.new(TestHelper.unreachable_route)
      # end
      # @concurrency = 3
      @ping = Net::Ping2::ICMP.new()
      @ping_with_host = Net::Ping2::ICMP.new(:host => LOCALHOST_IP)
    end

    check_ping_arguments
    check_class_methods
    check_attr_readers :data_size, :bind_host, :bind_port
    check_attr_accessors
    check_defaults :timeout => 5

    check_good_host_behaviour
    check_bad_hosts_behaviour(self.bad_hosts)

    check_thread_safety

=begin
    test "icmp ping basic functionality" do
      assert_respond_to(@icmp, :ping)
      omit_if(@@jruby)
      assert_nothing_raised { @icmp.ping }
    end

    test "icmp ping accepts a host" do
      omit_if(@@jruby)
      assert_nothing_raised { @icmp.ping(@host) }
    end

    test "icmp ping returns a boolean" do
      omit_if(@@jruby)
      assert_boolean(@icmp.ping)
      assert_boolean(@icmp.ping(@host))
    end

    test "icmp ping of local host is successful" do
      omit_if(@@jruby)
      assert_true(Net::Ping2::ICMP.new(@host).ping?)
      assert_true(Net::Ping2::ICMP.new('127.0.0.1').ping?)
    end

    test "threaded icmp ping returns expected results" do
      omit_if(@@jruby)
      ips = ['8.8.4.4', '8.8.9.9', '127.0.0.1', '8.8.8.8', '8.8.8.9']
      queue = Queue.new
      threads = []

      ips.each { |ip| queue << ip }

      @concurrency.times {
        threads << Thread.new(queue) do |q|
          ip = q.pop
          icmp = Net::Ping2::ICMP.new(ip, nil, 1)
          if ip =~ /9/
            assert_false(icmp.ping?)
          else
            assert_true(icmp.ping?)
          end
        end
      }

      threads.each { |t| t.join }
    end

    test "ping? is an alias for ping" do
      assert_respond_to(@icmp, :ping?)
      assert_alias_method(@icmp, :ping?, :ping)
    end

    test "icmp ping fails if host is invalid" do
      omit_if(@@jruby)
      assert_false(Net::Ping2::ICMP.new('bogus').ping?)
      assert_false(Net::Ping2::ICMP.new('http://www.asdfhjklasdfhlkj.com').ping?)
    end

    test "bind method basic functionality" do
      assert_respond_to(@icmp, :bind)
      assert_nothing_raised { @icmp.bind(Socket.gethostname) }
      assert_nothing_raised { @icmp.bind(Socket.gethostname, 80) }
    end

    test "duration method basic functionality" do
      omit_if(@@jruby)
      assert_nothing_raised { @icmp.ping }
      assert_respond_to(@icmp, :duration)
      assert_kind_of(Float, @icmp.duration)
    end

    test "host getter method basic functionality" do
      assert_respond_to(@icmp, :host)
      assert_equal(@host, @icmp.host)
    end

    test "host setter method basic functionality" do
      assert_respond_to(@icmp, :host=)
      assert_nothing_raised { @icmp.host = '127.0.0.1' }
      assert_equal(@icmp.host, '127.0.0.1')
    end

    test "port method basic functionality" do
      assert_respond_to(@icmp, :port)
      assert_equal(nil, @icmp.port)
    end

    test "timeout getter method basic functionality" do
      assert_respond_to(@icmp, :timeout)
      assert_equal(5, @icmp.timeout)
    end

    test "timeout setter method basic functionality" do
      assert_respond_to(@icmp, :timeout=)
      assert_nothing_raised { @icmp.timeout = 7 }
      assert_equal(7, @icmp.timeout)
    end

    test "timeout works as expected" do
      omit_if(@@jruby)
      icmp = Net::Ping2::ICMP.new('bogus.com', nil, 0.000001)
      assert_false(icmp.ping?)
      assert_equal('timeout', icmp.exception)
    end

    test "exception method basic functionality" do
      assert_respond_to(@icmp, :exception)
    end

    test "exception method returns nil if no ping has happened yet" do
      assert_nil(@icmp.exception)
    end

    test "warning method basic functionality" do
      assert_respond_to(@icmp, :warning)
    end

    test "data_size getter method basic functionality" do
      assert_respond_to(@icmp, :data_size)
      assert_nothing_raised { @icmp.data_size }
      assert_kind_of(Numeric, @icmp.data_size)
    end

    test "data_size returns expected value" do
      assert_equal(56, @icmp.data_size)
    end

    test "data_size setter method basic functionality" do
      assert_respond_to(@icmp, :data_size=)
      assert_nothing_raised { @icmp.data_size = 22 }
    end

    test "setting an odd data_size is valid" do
      omit_if(@@jruby)
      assert_nothing_raised { @icmp.data_size = 57 }
      assert_boolean(@icmp.ping)
    end

    test 'ping should fail for an unreachable website' do
      omit_unless(@unreachable_host)
      @unreachable_host.timeout = 3
      assert_false(@unreachable_host.ping?)
    end

    test 'ping should fail for a website on an unreachable route' do
      omit_unless(@unreachable_route)
      @unreachable_route.timeout = 3
      assert_false(@unreachable_route.ping?)
    end

    test 'ping should fail for a black hole' do
      @blackhole.timeout = 3
      assert_false(@blackhole.ping?)
    end

    test "pinging an unreachable host returns after the timeout" do
      omit_unless(@unreachable_host)
      @unreachable_host.timeout = 1
      tolerance = 0.5
      start_time = Time.now
      res = @unreachable_host.ping
      elapsed = Time.now - start_time
      assert_true(elapsed < @unreachable_host.timeout + tolerance,
                  'Expected elapsed (%1.1f) to be < timeout (%d) + tolerance (%1.1f), ping = %s, exception = %s' %
                      [elapsed, @unreachable_host.timeout, tolerance, res, @unreachable_host.exception.inspect])
    end


    test "pinging a host on an unreachable network returns after the timeout" do
      omit_unless(@unreachable_route)
      @unreachable_route.timeout = 1
      tolerance = 0.5
      start_time = Time.now
      res = @unreachable_route.ping
      elapsed = Time.now - start_time
      assert_true(elapsed < @unreachable_route.timeout + tolerance,
                  'Expected elapsed (%1.1f) to be < timeout (%d) + tolerance (%1.1f), ping = %s, exception = %s' %
                      [elapsed, @unreachable_route.timeout, tolerance, res, @unreachable_route.exception.inspect])
    end


    test "pinging a blackhole returns after the timeout" do
      @blackhole.timeout = 1
      tolerance = 0.5
      start_time = Time.now
      res = @blackhole.ping
      elapsed = Time.now - start_time
      assert_true(elapsed < @blackhole.timeout + tolerance,
                  'Expected elapsed (%1.1f) to be < timeout (%d) + tolerance (%1.1f), ping = %s, exception = %s' %
                      [elapsed, @blackhole.timeout, tolerance, res, @blackhole.exception.inspect])
    end

    test "pinging a blackhole waits for timeout" do
      @blackhole.timeout = 3
      tolerance = 0.5
      start_time = Time.now
      res = @blackhole.ping
      elapsed = Time.now - start_time
      assert_true(elapsed > @blackhole.timeout - tolerance,
                  'Expected elapsed (%1.1f) to be > timeout (%d) - tolerance (%1.1f), ping = %s, exception = %s' %
                      [elapsed, @blackhole.timeout, tolerance, res, @blackhole.exception.inspect])
    end
=end

  else
    def test_new_raises_exception
      assert_raise(NotImplementedError) { Net::Ping2::ICMP.new }
    end

    def tests_are_disabled
      omit('tests are disabled: ' + Net::Ping2::ICMP.not_available_message)
    end
  end


end

