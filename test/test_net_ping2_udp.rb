########################################################################
# test_net_ping_udp.rb
#
# Test case for the Net::Ping2::UDP class. This should be run via the
# 'test' or 'test:udp' Rake tasks.
#
# If someone could provide me a host where a udp ping actually
# works (with a service check), I would appreciate it. :)
########################################################################
require File.expand_path('../test_helper.rb', __FILE__)
require 'net/ping2/udp'

class TestNetPing2UDP < Test::Unit::TestCase
  if Net::Ping2::UDP.available?

    def setup
      # @host = '127.0.0.1'
      # @ping = Net::Ping2::UDP.new(@host)
      # @ping.service_check = false
      # @ping_service = Net::Ping2::UDP.new(@host)
      # @ping_service.service_check = true
      # @unused_port = TestHelper.blackhole_port
      # @blackhole = TestHelper.blackhole_ip
      # @unreachable_host = TestHelper.unreachable_host
      # @unreachable_route = TestHelper.unreachable_route
      @ping = Net::Ping2::UDP.new()
      @ping_with_host = Net::Ping2::UDP.new(:host => LOCALHOST_IP)
    end

    check_ping_arguments
    check_class_methods
    check_attr_readers
    check_attr_accessors :port, :service_check
    check_defaults :service_check => false, :port => 7

    check_good_host_behaviour
    check_bad_hosts_behaviour(self.bad_hosts)

    check_good_service_check
    check_bad_service_check

    check_thread_safety

=begin
    test 'ping basic functionality' do
      assert_respond_to(@ping, :ping)
      assert_raises(ArgumentError) { @ping.ping }
    end

    test 'ping accepts a host as an argument' do
      assert_nothing_raised { @ping.ping(@host) }
    end

    test 'a successful udp ping returns true' do
      assert_true(@ping.ping?(@host))
    end

    test 'bind basic functionality' do
      assert_respond_to(@ping, :bind)
      assert_nothing_raised { @ping.bind('127.0.0.1', 80) }
    end

    test 'duration basic functionality' do
      assert_nothing_raised { @ping.ping }
      assert_respond_to(@ping, :duration)
      assert_kind_of(Float, @ping.duration)
    end

    test 'host basic functionality' do
      assert_respond_to(@ping, :host)
      assert_respond_to(@ping, :host=)
      assert_equal('127.0.0.1', @ping.host)
    end

    test 'port basic functionality' do
      assert_respond_to(@ping, :port)
      assert_respond_to(@ping, :port=)
      assert_equal(7, @ping.port)
    end

    test 'timeout basic functionality' do
      assert_respond_to(@ping, :timeout)
      assert_respond_to(@ping, :timeout=)
    end

    test 'timeout default value is five' do
      assert_equal(5, @ping.timeout)
    end

    test 'exception basic functionality' do
      assert_respond_to(@ping, :exception)
    end

    test 'the exception attribute returns nil if the ping is successful' do
      assert_true(@ping.ping?(@host))
      assert_nil(@ping.exception)
    end

    test 'the exception attribute is not nil if the ping is unsuccessful' do
      assert_false(@ping.ping?('www.ruby-lang.org'))
      assert_not_nil(@ping.exception)
    end

    test 'warning basic functionality' do
      assert_respond_to(@ping, :warning)
    end

    test 'the warning attribute returns nil if the ping is successful' do
      assert_true(@ping.ping?(@host))
      assert_nil(@ping.warning)
    end

    test 'service_check basic functionality' do
      assert_respond_to(Net::Ping2::UDP, :service_check)
      assert_respond_to(Net::Ping2::UDP, :service_check=)
    end

    test 'service_check attribute has been set to false' do
      assert_false(Net::Ping2::UDP.service_check)
    end

    test 'service_check getter method does not accept arguments' do
      assert_raise(ArgumentError) { Net::Ping2::UDP.service_check(1) }
    end

    test 'service_check setter method only accepts boolean arguments' do
      assert_raise(ArgumentError) { Net::Ping2::UDP.service_check = 1 }
    end

    def test_ping_service_check_true_on_open_port
      msg = "checks localhost port #{@port} is alive +this test will fail if that port is not open on this system+"
      res = @ping.ping?(@host, 3, @port)
      assert_true(res, msg + ", exception = #{@ping.exception}")
    end

    def test_ping_service_check_true_on_unused_port
      msg = "checks localhost port #{@unused_port} is NOT alive +this test will fail if that port IS open on this system+"
      res = @ping_service.ping?(@host, 3, @open_port)
      assert_false(res, msg + ", exception = #{@ping_unused_port.exception}")
    end

    def test_ping_service_check_false_on_closed_port
      msg = "checks localhost port #{@ping_unused_port.port}, but should return true even if it is closed"
      res = @ping_unused_port.ping?
      assert_true(res, msg + ", exception = #{@ping_unused_port.exception}")
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


    test "pinging a host on an unreacable network returns after the timeout" do
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


    test "pinging a black hole returns after the timeout" do
      @blackhole.timeout = 1
      tolerance = 0.5
      start_time = Time.now
      res = @blackhole.ping
      elapsed = Time.now - start_time
      assert_true(elapsed < @blackhole.timeout + tolerance,
                  'Expected elapsed (%1.1f) to be < timeout (%d) + tolerance (%1.1f), ping = %s, exception = %s' %
                      [elapsed, @blackhole.timeout, tolerance, res, @blackhole.exception.inspect])
    end

    test "pinging a black hole waits for timeout" do
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
      assert_raise(NotImplementedError) { Net::Ping2::UDP.new }
    end

    def tests_are_disabled
      omit('tests are disabled: ' + Net::Ping2::UDP.not_available_message)
    end

  end

end
