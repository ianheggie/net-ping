########################################################################
# example_pingudp.rb
#
# A short sample program demonstrating a UDP ping. You can run
# this program via the example:udp task. Modify as you see fit.
########################################################################
require 'net/ping2'

host = 'www.google.com'

if Net::Ping2::UDP.available?
  puts "== PING UTP =="

  puts "-- Ping to #{host} expected to fail"

  u = Net::Ping2::UDP.new(:host => host)
  p u.ping?
else
  puts '[UTP ping not supported for this ruby]'
end
