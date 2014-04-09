#######################################################################
# test_net_ping_wmi.rb
#
# Test case for the Net::Ping2::WMI class. These tests will only be
# run MS Windows.  You should run this test via the 'test' or
# 'test:wmi' Rake task.
#######################################################################
require File.expand_path('../test_helper.rb', __FILE__)
require 'net/ping2/wmi'

class TestNetPing2WMI < Test::Unit::TestCase

  if Net::Ping2::WMI.available?

    def setup
      @host = "www.ruby-lang.org"
      @ping = Net::Ping2::WMI.new
      @ping_with_host = Net::Ping2::WMI.new(:host => LOCALHOST_IP)
    end

    check_ping_arguments
    check_class_methods
    check_attr_readers
    check_attr_accessors
    check_defaults :timeout => 5

    check_good_host_behaviour
    check_bad_hosts_behaviour(self.bad_hosts)

    check_thread_safety


    def test_ping_basic
      assert_respond_to(@ping_with_host, :ping)
      # noinspection RubyArgCount
      assert_raise(ArgumentError) { @ping.ping }
    end

    def test_ping_with_host
      assert_nothing_raised { @ping.ping(@host) }
    end

    def test_ping_with_options
      assert_nothing_raised { @ping.ping(@host, :NoFragmentation => true) }
    end

    def test_ping_returns_struct
      assert_kind_of(Struct::PingStatus, @ping_with_host.ping)
    end

    def test_ping_returns_boolean
      assert_boolean(@ping_with_host.ping?)
      assert_boolean(@ping.ping?(@host))
    end

    def test_ping_expected_failure
      assert_false(@ping.ping?('bogus'))
      assert_false(@ping.ping?('http://www.asdfhjklasdfhlkj.com'))
    end

    def test_exception
      assert_respond_to(@ping, :exception)
      assert_nothing_raised { @ping.ping(LOCALHOST_IP) }
      assert_nil(@ping.exception)
    end

    def test_warning
      assert_respond_to(@ping, :warning)
    end

  else
    def test_new_raises_exception
      assert_raise(NotImplementedError) { Net::Ping2::WMI.new }
    end

    def tests_are_disabled
      omit('tests are disabled: ' + Net::Ping2::WMI.not_available_message)
    end
  end
end