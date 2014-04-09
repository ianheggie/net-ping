#########################################################################
# test_net_ping_external.rb
#
# Test case for the Net::PingExternal class. Run this via the 'test' or
# 'test:external' rake task.
#
# WARNING: I've noticed that test failures will occur if you're using
# OpenDNS. This is apparently caused by them messing with upstream
# replies for advertising purposes.
#########################################################################
require File.expand_path('../test_helper.rb', __FILE__)

require 'net/ping2/external'

class TestNetPing2External < Test::Unit::TestCase

  if Net::Ping2::External.available?

    def setup
      @ping = Net::Ping2::External.new()
      @ping_with_host = Net::Ping2::External.new(:host => LOCALHOST_IP)
    end

    check_ping_arguments
    check_class_methods
    check_attr_readers
    check_attr_accessors
    check_defaults :timeout => 5

    check_good_host_behaviour
    check_bad_hosts_behaviour(self.bad_hosts, %w{response})

    check_thread_safety

=begin

    test "pinging a good host returns true" do
      assert_true(@ping.ping?(LOCALHOST_IP))
      check_common_assertions(@ping)
    end

    test "pinging a bogus host returns false" do
      assert_false(@ping.ping?(BOGUS_HOST))
      check_common_assertions(@ping)
    end

    test "pinging a good host sets duration to a float" do
      assert_nothing_raised { @ping.ping(LOCALHOST_IP) }
      assert_kind_of(Float, @ping.duration)
    end

    # Set only for bad hosts
    SET_FOR_BAD_HOSTS.each do |method|
      test "#{method} is set for a bad host then unset for following good ping" do
        assert_nil(@ping.send(method))
        assert_false(@ping.ping?(BOGUS_HOST))
        assert_not_nil(@ping.send(method))
        assert_true(@ping.ping(LOCALHOST_IP))
        assert_nil(@ping.send(method))
      end
    end

    SET_FOR_GOO_HOSTS.each do |method|
      test "#{method} is set for a good host then unset for following bad ping" do
        assert_nil(@ping.send(method))
        assert_nothing_raised { @ping.ping(LOCALHOST_IP) }
        assert_not_nil(@ping.send(method))
        assert_false(@ping.ping?(BOGUS_HOST))
        assert_nil(@ping.send(method))
      end

    end

    TestHelper.bad_hosts.each do |name, host, port|
      test "ping should fail for #{name}" do
        assert_false(@ping.ping?(host, :timeout => 2))
        SET_FOR_BAD_HOSTS.each do |method|
          assert_not_nil(@ping.send(method))
        end
        SET_FOR_GOOD_HOSTS.each do |method|
          assert_nil(@ping.send(method))
        end
      end

      test "pinging #{name} returns within timeout" do
        start_time = Time.now
        res = @ping.ping?(host, :timeout =>  1)
        elapsed = Time.now - start_time
        assert_true(elapsed < 1.5,
                    'Expected elapsed (%1.1f) to be < 1.5, ping returned %s with exception = %s' %
                        [elapsed, res, @ping.exception.inspect])
      end
    end


    test "pinging a blackhole waits for timeout" do
      omit_unless TestHelper.blackhole_ip, 'Set BLACKHOLE_IP to an IP# that returns no packets to enable'
      # sanity check that it is a black hole we are testing
      start_time = Time.now
      res = @ping.ping(TestHelper.blackhole_ip, :timeout =>  1)
      elapsed = Time.now - start_time
      assert_true(elapsed >0.5,
                  'Expected elapsed (%1.1f) to be > 0.5, ping = %s, exception = %s' %
                      [elapsed, res, @ping.exception.inspect])
      #assert_not_nil(@ping.exception)
    end
=end

  else
    def test_new_raises_exception
      assert_raise(NotImplementedError) { Net::Ping2::External.new }
    end

    def tests_are_disabled
      omit('tests are disabled: ' + Net::Ping2::External.not_available_message)
    end

  end

end
