#!/usr/bin/env ruby

# Defaults

class TestHelper

  DEFAULT_BLACKHOLE_IP = '144.140.108.23' # telstra.com - aussie ISP that drops packets
  DEFAULT_BLACKHOLE_PORT = 1001

  def self.local_tcp_port
    (ENV['LOCAL_TCP_PORT'] || 22).to_i
  end

  #def self.local_udp_port
  #  ENV['LOCAL_UDP_PORT'].to_i if ENV['LOCAL_UDP_PORT']
  #end

  def self.unreachable_host
    ENV['UNREACHABLE_HOST'] != '' && ENV['UNREACHABLE_HOST']
  end

  def self.unreachable_route
    ENV['UNREACHABLE_ROUTE'] != '' && ENV['UNREACHABLE_ROUTE']
  end

  def self.blackhole_ip
    if ENV['BLACKHOLE_IP'].to_s =~ /(\S+)/
      $1
    else
      DEFAULT_BLACKHOLE_IP
    end
  end

  def self.blackhole_port
    if ENV['BLACKHOLE_PORT'].to_s =~ /(\d+)/
      $1.to_i
    else
      DEFAULT_BLACKHOLE_PORT
    end
  end

  def self.unreachable_host_url
    'http://%s:%d/' % [TestHelper.unreachable_host, TestHelper.blackhole_port] if TestHelper.unreachable_host
  end

  def self.unreachable_route_url
    'http://%s:%d/' % [TestHelper.unreachable_route, TestHelper.blackhole_port] if TestHelper.unreachable_route
  end

  def self.blackhole_url
    'http://%s:%d/' % [TestHelper.blackhole_ip, TestHelper.blackhole_port] if TestHelper.blackhole_ip
  end

  def self.allow_net_connect
    res = '127.0.0.1'
    res << '|' << self.unreachable_host if self.unreachable_host
    res << '|' << self.unreachable_route if self.unreachable_route
    res << '|' << self.blackhole_ip if self.blackhole_ip
    %r[^https?://(#{res.gsub('.', '\.')})]
  end

end
