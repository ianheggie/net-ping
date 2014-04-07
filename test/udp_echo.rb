require 'socket'
host = 'localhost'
s = UDPSocket.new
if s.respond_to? :local_address
  s.bind(nil, 0)
  port = s.local_address.ip_port
else
  # rbx doesn't have local_address
  port = 12345
  s.bind(nil, port)
end
STDOUT.puts port
puts "Ready to echo one udp packet..."
STDOUT.flush
text, sender = s.recvfrom(16)
remote_host = sender[3]
remote_port = sender[1]
puts "#{remote_host}:#{remote_port} sent #{text}, echoing it back ..."
s.send(text, 0, remote_host, remote_port)
s.close
puts "udp_echo finished"
