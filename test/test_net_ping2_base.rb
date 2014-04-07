# Test base functionality

require File.expand_path('../test_helper.rb', __FILE__)
require 'net/ping2/base'

class TestNetPing2Base < Test::Unit::TestCase
  #extend TestHelper

  def setup
    @ping = Net::Ping2::Base.new
    @ping_with_host = Net::Ping2::Base.new(:host => LOCALHOST_IP)
  end

  check_ping_arguments
  check_class_methods
  check_attr_readers
  check_attr_accessors
  check_defaults :timeout => 5

  test 'ping? returns false' do
    assert_false(@ping.ping?(LOCALHOST_IP))
  end

  test 'ping returns nil' do
    assert_nil(@ping.ping(LOCALHOST_IP))
  end

end
