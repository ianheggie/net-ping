########################################################################
# example_pingexternal.rb
#
# A short sample program demonstrating an external ping. You can run
# this program via the example:external task. Modify as you see fit.
########################################################################
require 'net/ping2'

good = 'www.rubyforge.org'
bad = 'foo.bar.baz'

puts "== PING External =="

puts "-- Good ping"

p1 = Net::Ping2::External.new(:host => good)
p p1.ping?

puts "-- Bad ping"

p2 = Net::Ping2::External.new()
p p2.ping?(bad)
