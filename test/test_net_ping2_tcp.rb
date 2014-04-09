#####################################################################
# test_net_ping_tcp.rb
#
# Test case for the Net::PingTCP class. This test should be run via
# the 'test' or 'test:tcp' Rake task.
#####################################################################
require File.expand_path('../test_helper.rb', __FILE__)
require 'net/ping2/tcp'
include Net

class TestNetPing2Tcp < Test::Unit::TestCase

  if Net::Ping2::TCP.available?

    def setup
      # @host = 'localhost'
      # @bad = TestHelper.bad_hostname_uri
      # @port = TestHelper.local_tcp_port
      # @ping = Net::Ping2::TCP.new(30)
      # @ping.service_check = false
      # @ping_service = Net::Ping2::TCP.new(30)
      # @ping_service.service_check = true
      # @unused_port = TestHelper.blackhole_port
      # @blackhole = TestHelper.blackhole_ip
      # @unreachable_host = TestHelper.unreachable_host
      # @unreachable_route = TestHelper.unreachable_route


      @ping = Net::Ping2::TCP.new()
      @ping_with_host = Net::Ping2::TCP.new(:host => LOCALHOST_IP)

    end

    check_ping_arguments
    check_class_methods
    check_attr_readers
    check_attr_accessors :port, :service_check
    check_defaults :service_check => false, :port => 80

    check_good_host_behaviour
    check_bad_hosts_behaviour(self.bad_hosts)

    check_good_service_check :port => 22
    #check_bad_service_check :port => 22

    check_thread_safety


=begin
    %w{service_check}.each do |method|
      setter = "#{method}="
      test "has working #{setter} method" do
        assert_respond_to(@ping, setter)
        @ping.send(setter, 42)
        assert_equal(42, @ping.send(method))
      end
    end

    test 'ping requires host argument' do
      #noinspection RubyArgCount
      assert_raise(ArgumentError) { @ping.ping }
    end

    test 'ping returns a boolean value' do
      assert_boolean(@ping.ping?(@host, @port))
      assert_boolean(@ping.ping?(@bad))
    end

    test 'ping should succeed for a valid host' do
      assert_true(@ping.ping?(@host, @port))
    end

    test 'ping should succeed for a valid host with service_check=true' do
      assert_true(@ping_service.ping?(@host, @port))
    end

    test 'ping should fail for a valid host and an unused port with service_check=true' do
      assert_false(@ping_service.ping?(@host, @unused_port))
    end

    TestHelper.bad_hosts.each do |name, host, port|
      test "ping should fail for #{name}" do
        assert_false(@ping.ping?(host, 3, port))
      end

      test "pinging #{name} returns within timeout" do
        start_time = Time.now
        res = @ping.ping?(host, 1, port)
        elapsed = Time.now - start_time
        assert_true(elapsed < 1.5,
                    'Expected elapsed (%1.1f) to be < 1.5, ping returned %s with exception = %s' %
                        [elapsed, res, @ping.exception.inspect])
      end

      test "ping should fail for #{name} with service_check=true" do
        assert_false(@ping_service.ping?(host, 3, port))
      end

      test "pinging #{name} with service_check=true returns within timeout" do
        start_time = Time.now
        res = @ping_service.ping?(host, 1, port)
        elapsed = Time.now - start_time
        assert_true(elapsed < 1.5,
                    'Expected elapsed (%1.1f) to be < 1.5, ping returned %s with exception = %s' %
                        [elapsed, res, @ping_service.exception.inspect])
      end
    end

    test 'duration returns a float value on a successful ping' do
      assert_true(@ping.ping?(@host, @port))
      assert_kind_of(Float, @ping.duration)
    end

    test 'duration is nil on an unsuccessful ping' do
      assert_false(@ping.ping?(@bad))
      assert_nil(@ping.duration)
    end

    test 'port attribute expected value' do
      assert_equal(80, @ping.port)
    end

    test 'timeout attribute expected values' do
      assert_equal(30, @ping.timeout)
    end

    test 'pinging a black hole waits for timeout' do
      omit_unless TestHelper.blackhole_ip
      start_time = Time.now
      res = @ping.ping?(TestHelper.blackhole_ip, 1, TestHelper.blackhole_port)
      elapsed = Time.now - start_time
      assert_true(elapsed > 0.5,
                  'Expected elapsed (%1.1f) to be > 0.5, ping returned %s, exception = %s' %
                      [elapsed, res, @ping.exception.inspect])
    end

    def slow_server
      echo_cmd = File.expand_path('../slow_server.rb', __FILE__)
      echo_process = IO.popen('ruby %s' % echo_cmd, 'r')
      port = echo_process.gets.to_i
      slow = Net::Ping2::TCP.new(1)
      [echo_process, port, slow, Time.now]
    end

    def stop_slow_server(echo_process)
      Process.kill('TERM', echo_process.pid)
      echo_process.close
    end

    test 'pinging a slow host returns after the timeout' do
      echo_process, port, slow, start_time = slow_server
      res = slow.ping('127.0.0.1', 1, port)
      elapsed = Time.now - start_time
      stop_slow_server(echo_process)
      assert_true(elapsed < 1.5,
                  'Expected elapsed (%1.1f) to be < 1.5, ping returned %s, exception = %s' %
                      [elapsed, res, slow.exception.inspect])
    end

    test 'pinging a slow host waits for timeout' do
      echo_process, port, slow, start_time = slow_server
      res = slow.ping('127.0.0.1', 1, port)
      elapsed = Time.now - start_time
      stop_slow_server(echo_process)
      assert_true(elapsed > 0.5,
                  'Expected elapsed (%1.1f) to be > 0.5, ping = %s, exception = %s' %
                      [elapsed, res, slow.exception.inspect])
    end

    test 'exception attribute is nil if the ping is successful' do
      assert_true(@ping.ping?(@host, @port))
      assert_nil(@ping.exception)
    end

    test 'exception attribute is not nil if the ping is unsuccessful' do
      assert_false(@ping.ping?(@bad))
      assert_not_nil(@ping.exception)
    end
=end

  else
    def test_new_raises_exception
      assert_raise(NotImplementedError) { Net::Ping2::TCP.new }
    end

    def tests_are_disabled
      omit('tests are disabled: ' + Net::Ping2::TCP.not_available_message)
    end

  end

end
