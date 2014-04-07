#!/usr/bin/env ruby
#
# Run with:
# rvmsudo ruby test/check_icmp_with_threads.rb
# # or
# rbenv sudo ruby test/check_icmp_with_threads.rb

require 'rubygems'
require 'bundler/setup'
require 'net/ping'
require 'thread'

# inaccurate with CONCURRENCY = 2
# ok with CONCURRENCY = 1
CONCURRENCY = (ENV['CONCURRENCY'] || 2).to_i

threads = []
queue = Queue.new

# Here are four ips that should return pings and two non-exist ip
ips = ['8.8.4.4', '8.8.9.9', '127.0.0.1', '8.8.8.8', '8.8.8.9', '127.0.0.2']
ips.each do |i|
  queue << i
end

CONCURRENCY.times do
  threads << Thread.new(queue) do |q|
    while !q.empty?
      ip = q.pop
      expect_failure = ip =~ /9$/
      ping = Net::Ping::ICMP.new(ip, nil, 1)
      if ping.ping
        puts "ping #{ip} returned true, which #{expect_failure ? 'is NOT' : 'IS'} as expected"
        exit 1 if expect_failure
      else
        puts "check ping #{ip} returned false, with exception: #{ping.exception}, which #{expect_failure ? 'IS' : 'is NOT'} as expected"
        exit 1 unless expect_failure
      end
    end
  end
end
puts 'Waiting for threads'
threads.each { |t| t.join }
puts 'Finished without error'
