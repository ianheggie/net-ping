require 'net/ping2/base'

if File::ALT_SEPARATOR
  require 'win32/security'
end

# The Net module serves as a namespace only.
module Net

  # The Net::Ping2::ICMP class encapsulates an icmp ping.
  class Ping2::ICMP < Ping2::Base

    ICMP_ECHOREPLY = 0 # Echo reply
    ICMP_ECHO = 8 # Echo request
    ICMP_SUBCODE = 0

    # Returns the data size, i.e. number of bytes sent on the ping. The
    # default size is 56.
    #
    attr_accessor :data_size

    attr_reader :bind_host
    attr_reader :bind_port

    def self.not_available_message
      return 'JRUBY-5897 - ICMP and SOCK_RAW sockets are not supported (marked Won\'t Fix)' if defined? JRUBY_VERSION
      return 'ICMP requires root privileges' if Process.euid > 0
      if File::ALT_SEPARATOR
        unless Win32::Security.elevated_security?
          return PermissionError, 'ICMP requires elevated security'
        end
      end
      return "ICMP not supported in Rubinius due to something returning string not list" if defined? Rubinius
      return "ICMP not supported in Windows due to Errno::EAFNOSUPPORT An address incompatible with the requested protocol was used. bugs" if File::ALT_SEPARATOR
      nil
    end


    # Creates and returns a new Net::Ping2::ICMP object.  This is similar to its
    # superclass constructor, but must be created with root privileges (on
    # UNIX systems), and the port value is ignored.
    #
    def initialize(options = {})
      @seq = 0
      @bind_port = 0
      @bind_host = nil
      @data_size = 56

      @ping_id = (Thread.current.object_id ^ Process.pid) & 0xffff

      super(options)
    end


    # Associates the local end of the socket connection with the given
    # +host+ and +port+. The default port is 0.
    #
    def bind(host, port = 0)
      @bind_host = host
      @bind_port = port
    end

    # Pings the +host+ specified in this method or in the constructor.  If a
    # host was not specified either here or in the constructor, an
    # ArgumentError is raised.
    #
    def ping(host = @host, options = {})
      super(host, options)
      @success = false

      opt1 = (options.key?(:port) ? {:data_must_match => (options[:port] == 7)} : {})
      opt2 = {
          :timeout => @timeout,
          :bind_host => @bind_host,
          :bind_port => @bind_port,
          :data_size => @data_size}
      options = opt1.merge(opt2).merge(options)

      data = ''
      0.upto(options[:data_size]) { |n| data << (n % 256).chr }

      socket = Socket.new(
          Socket::PF_INET,
          Socket::SOCK_RAW,
          Socket::IPPROTO_ICMP
      )

      if options.key? :bind_host
        saddr = Socket.pack_sockaddr_in(options[:bind_port], options[:bind_host])
        socket.bind(saddr)
      end

      @seq = (@seq + 1) % 65536
      pstring = 'C2 n3 A' << options[:data_size].to_s

      checksum = 0
      msg = [ICMP_ECHO, ICMP_SUBCODE, checksum, @ping_id, @seq, data].pack(pstring)

      checksum = checksum(msg)
      msg = [ICMP_ECHO, ICMP_SUBCODE, checksum, @ping_id, @seq, data].pack(pstring)

      begin
        saddr = Socket.pack_sockaddr_in(0, host)
      rescue Exception => err
        @exception = err
        socket.close if socket && !socket.closed?
        return @success
      end

      start_time = Time.now

      begin
        socket.send(msg, 0, saddr) # Send the message
      rescue Errno::ENETUNREACH => err
        # rescue from unreachable host or network
        @exception = err
        socket.close if socket && !socket.closed?
        return @success
      end

      begin
        while true
          io_array = select([socket], nil, nil, options[:timeout])

          if io_array.nil? || io_array[0].empty?
            @exception = "timeout" if io_array.nil?
            return false
          end

          ping_id = nil
          seq = nil

          @response = socket.recvfrom(1500).first
          type = @response[20, 2].unpack('C2').first

          case type
            when ICMP_ECHOREPLY
              if data.length >= 28
                ping_id, seq = @response[24, 4].unpack('n3')
              end
            else
              if data.length > 56
                ping_id, seq = @response[52, 4].unpack('n3')
              end
          end

          if ping_id == @ping_id && seq == @seq && type == ICMP_ECHOREPLY
            @success = true
            break
          end
        end
      rescue Exception => err
        @exception = err
      ensure
        socket.close if socket && !socket.closed?
      end

      # There is no duration if the ping failed
      @duration = Time.now - start_time if @success

      @success
    end

    private

    # Perform a checksum on the message.  This is the sum of all the short
    # words and it folds the high order bits into the low order bits.
    #
    def checksum(msg)
      length = msg.length
      num_short = length / 2
      check = 0

      msg.unpack("n#{num_short}").each do |short|
        check += short
      end

      if length % 2 > 0
        check += msg[length-1, 1].unpack('C').first << 8
      end

      check = (check >> 16) + (check & 0xffff)
      return (~((check >> 16) + check) & 0xffff)
    end
  end
end
