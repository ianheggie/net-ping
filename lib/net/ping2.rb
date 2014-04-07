require "net/ping2/version"

# By doing a "require 'net/ping2'" you are requiring every subclass.  If you
# want to require a specific ping type only, do "require 'net/ping2/tcp'",
# for example.

require 'net/ping2/tcp'
require 'net/ping2/udp'
require 'net/ping2/icmp'
require 'net/ping2/external'
require 'net/ping2/http'
require 'net/ping2/wmi'

module Net
  module Ping2
    def self.new(protocol = 'http', options = {})
      klass_name = protocol =~ /^external$/i ? 'External' : protocol.upcase
      Net::Ping2.const_get(klass_name).new(options)
    end
  end
end

