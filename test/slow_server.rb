#!/usr/bin/env ruby
#
# Returns a response after 20 seconds
#
require 'socket'

host = '127.0.0.1'
server = TCPServer.new(host, 0)
if server.respond_to? :addr
  port = server.addr[1]
else
  # rbx doesn't have local_address
  port = 12345
  server = TcpSocket.new(host, port)
end
delay = (ARGV.first || 20).to_i
STDOUT.puts port
STDERR.puts "Slow server waiting for tcp or http://127.0.0.1:#{port} connection."
STDOUT.flush
STDERR.flush

client = server.accept()
STDERR.puts "Got request, Delaying #{delay} seconds"
STDERR.flush
Signal.trap("TERM") do
  STDERR.puts "Terminating as requested..."
  exit 2
end
sleep(delay)
resp = "Delayed #{delay} seconds\n"
header = ["HTTP/1.0 200 OK",
          "Server: Ruby",
          "Content-Type: text/plain",
          "Content-Length: #{resp.length}",
          '',
          ''].join("\r\n")
STDERR.puts "Responding with #{header.length} chars in header and #{resp.length} in body ..."
STDERR.flush
client.write header
client.write resp
client.close
STDERR.puts "slow_server finished"
STDERR.flush
