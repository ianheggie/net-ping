######################################################################
# test_net_ping.rb
#
# Test suite for all the Ping subclasses. Note that the Net::Ping2::ICMP
# class test won't be run unless this is run as a privileged process.
######################################################################

require 'test-unit'
require 'net/ping2'
require File.expand_path('../test_helper.rb', __FILE__)


class ATestCaseClass
  extend TestHelper
end

class TestNetPing2 < Test::Unit::TestCase
  def test_net_ping_version
    assert_match(/^\d+\.\d+\.\d+$/, Net::Ping2::VERSION)
  end

  def test_test_helper_allow_net_connect
    assert_true(!!("http://127.0.0.1/fred" =~ ATestCaseClass.allow_net_connect))
    assert_false(!!("http://127.0.1.1/fred" =~ ATestCaseClass.allow_net_connect))
  end

  def test_default_factory
    assert_kind_of(Net::Ping2::HTTP, Net::Ping2.new())
    assert_equal(5, Net::Ping2.new().timeout)
  end

  def test_icmp_factory
    omit_unless Net::Ping2::ICMP.available?, Net::Ping2::ICMP.not_available_message
    assert_kind_of(Net::Ping2::ICMP, Net::Ping2.new('icmp'))
    assert_equal(7, Net::Ping2.new('icmp', :timeout => 7).timeout)
  end

  def test_external_factory
    omit_unless Net::Ping2::External.available?, Net::Ping2::External.not_available_message
    assert_kind_of(Net::Ping2::External, Net::Ping2.new('external'))
    assert_equal(7, Net::Ping2.new('external', :timeout => 7).timeout)
  end

  def test_http_factory
    omit_unless Net::Ping2::HTTP.available?, Net::Ping2::HTTP.not_available_message
    assert_kind_of(Net::Ping2::HTTP, Net::Ping2.new('http'))
    assert_equal(7, Net::Ping2.new('http', :timeout => 7).timeout)
    assert_equal(8000, Net::Ping2.new('http', :port => 8000).port)
  end

  def test_tcp_factory
    omit_unless Net::Ping2::TCP.available?, Net::Ping2::TCP.not_available_message
    assert_kind_of(Net::Ping2::TCP, Net::Ping2.new('tcp'))
    assert_equal(7, Net::Ping2.new('tcp', :timeout => 7).timeout)
    assert_equal(22, Net::Ping2.new('tcp', :port => 22).port)
  end

  def test_udp_factory
    omit_unless Net::Ping2::UDP.available?, Net::Ping2::UDP.not_available_message
    assert_kind_of(Net::Ping2::UDP, Net::Ping2.new('udp'))
    assert_equal(7, Net::Ping2.new('udp', :timeout => 7).timeout)
    assert_equal(88, Net::Ping2.new('udp', :port => 88).port)
  end

  def test_wmi_factory
    omit_unless Net::Ping2::WMI.available?, Net::Ping2::WMI.not_available_message
    assert_kind_of(Net::Ping2::WMI, Net::Ping2.new('wmi'))
    assert_equal(7, Net::Ping2.new('wmi', :timeout => 7).timeout)
  end


end
