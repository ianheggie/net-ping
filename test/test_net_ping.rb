######################################################################
# test_net_ping.rb
#
# Test suite for all the Ping subclasses. Note that the Ping::ICMP
# class test won't be run unless this is run as a privileged process.
######################################################################

require File.expand_path('../test_helper.rb', __FILE__)
$LOAD_PATH << File.expand_path('../', __FILE__)

unless ENV['EXCLUDE'].to_s =~ /external/
  # ruby 1.8.7 doesn't return thread from popen3, so exitstatus can't be checked
  require 'test_net_ping_external'
end
unless ENV['EXCLUDE'].to_s =~ /http/
  require 'test_net_ping_http'
end
unless ENV['EXCLUDE'].to_s =~ /tcp/
  require 'test_net_ping_tcp'
end
unless ENV['EXCLUDE'].to_s =~ /udp/
  # http://jira.codehaus.org/browse/JRUBY-6974 - Timeout.timeout not working using UDPSocket
  require 'test_net_ping_udp'
end

unless ENV['EXCLUDE'].to_s =~ /icmp/
  if File::ALT_SEPARATOR
    require 'win32/security'

    if Win32::Security.elevated_security?
      require 'test_net_ping_icmp'
    end
  else
    if Process.euid == 0
      require 'test_net_ping_icmp'
    end
  end
end

unless ENV['EXCLUDE'].to_s =~ /wmi/
  if File::ALT_SEPARATOR
    require 'test_net_ping_wmi'
  end
end

class TC_Net_Ping < Test::Unit::TestCase
  def test_net_ping_version
    assert_equal('1.7.3', Net::Ping::VERSION)
  end

  def test_test_helper_allow_net_connect
    assert_true( !!("http://127.0.0.1/fred" =~ TestHelper.allow_net_connect))
    assert_false( !! ("http://127.0.1.1/fred" =~ TestHelper.allow_net_connect))
  end

end
