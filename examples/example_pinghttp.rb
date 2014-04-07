########################################################################
# example_pinghttp.rb
#
# A short sample program demonstrating an http ping. You can run
# this program via the example:http task. Modify as you see fit.
########################################################################
require 'net/ping2'

good = 'http://www.google.com/index.html'
bad = 'http://www.ruby-lang.org/index.html'

puts "== PING HTTP =="

puts "-- Good ping, no redirect"

p1 = Net::Ping2::HTTP.new(:host => good)
p p1.ping?

puts "-- Bad ping"

p2 = Net::Ping2::HTTP.new()
p p2.ping?(bad)
p p2.warning
p p2.exception
