########################################################################
# example_pingtcp.rb
#
# A short sample program demonstrating a tcp ping. You can run
# this program via the example:tcp task. Modify as you see fit.
########################################################################
require 'net/ping2'

good = 'www.google.com'
bad = 'foo.bar.baz'

puts "== PING TCP =="

puts "-- Good ping"

p1 = Net::Ping2::TCP.new(:host => good, :port => 'http')
p p1.ping?

puts "-- Bad ping"

p2 = Net::Ping2::TCP.new()
p p2.ping?(bad)
