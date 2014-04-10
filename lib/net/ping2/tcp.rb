require 'net/ping2/base'

# The Net module serves as a namespace only.
module Net
  module Ping2

    # With a TCP ping simply try to open a connection. If we are successful,
    # assume success. In either case close the connection to be polite.
    #
    class TCP < Base

      MAX_DATA = 1024 # not too large - we aren't trying to be a client, just a ping!

      # The port to ping. Defaults to port 80.
      #
      attr_reader :port

      def port=(port)
        @service_check = true
        @port = port
      end

      # Returns if the service on that port is checked.
      # If false then Errno::ECONNREFUSED is considered a success
      #
      attr_accessor :service_check

      # The data to send to the remote host. By default this is nil.
      # This should be MAX_DATA size characters or less.
      #
      attr_reader :data

      # Sets the data string sent to the remote host. This value cannot have
      # a size greater than MAX_DATA.
      #
      def data=(string)
        if string.size > MAX_DATA
          err = "cannot set data string larger than #{MAX_DATA} characters"
          raise ArgumentError, err
        end
        @service_check = true
        @data = string
      end

      # Creates and returns a new Net::Ping2::TCP object.
      # The default port is 80,
      # The default timeout is 10 seconds.
      # service_check is false by default, unless port is explicitly set.
      def initialize(options = {})
        @port = 80
        @service_check = false
        @data = nil
        super(options)
      end

      # This method attempts to ping a host and port using a TCPSocket with
      # the host, port and timeout values passed in the constructor.  Returns
      # true if successful, or false otherwise.
      #
      # Note that, by default, an Errno::ECONNREFUSED return result will be
      # considered a failed ping. Set service_check = false
      # if you wish to change this behavior.
      #

      def ping(host = @host, options = {})
        super(host, options)

        opt1 = (options.key?(:port) || options.key?(:data) ? {:service_check => true} : {})
        opt2 = {
            :service_check => @service_check,
            :timeout => @timeout,
            :data => @data,
            :port => @port}
        options = opt1.merge(opt2).merge(options)

        start_time = Time.now

        # Failure here most likely means bad host, so just bail.
        begin
          addr = Socket.getaddrinfo(host, options[:port])
        rescue SocketError => err
          @exception = err
          return false
        end
        sock = nil
        begin
          # Where addr[0][0] is likely AF_INET.
          sock = Socket.new(Socket.const_get(addr[0][0]), Socket::SOCK_STREAM, 0)

          # This may not be entirely necessary
          sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

          begin
            # Where addr[0][3] is an IP address
            sock.connect_nonblock(Socket.pack_sockaddr_in(port, addr[0][3]))
          rescue Errno::EINPROGRESS => err
            @exception = err
              # No-op, continue below
          rescue Exception => err
            # Something has gone horribly wrong
            @exception = err
            return false
          end

          timeout = options[:timeout]
          if options[:data].nil? || options[:data].empty?
            resp = IO.select(nil, [sock], nil, options[:timeout])
          else
            resp = IO.select(nil, [sock], nil, timeout)
            unless resp.nil?
              sock.send(options[:data], 0)
              resp = IO.select([sock], nil, nil, options[:timeout])
            end
          end

          # Assume ECONNREFUSED at this point
          if resp.nil?
            if options[:service_check]
              @exception = Errno::ECONNREFUSED
            else
              @success = true
            end
          else
            @response = resp[0].empty? ? '' : sock.read_nonblock.to_s rescue ''
            #@response_data, ignore_addrinfo = sock.recvfrom(MAX_DATA)
            @success = true
          end
        ensure
          begin
            sock.close if sock
          rescue Errno::EBADF => err
            # JRuby throws this on unreachable_route
            @warning = "Socket.close error: #{err.message}"
          end
        end

        # There is no duration if the ping failed
        @duration = Time.now - start_time if @success
        @exception = nil if @success
        @success
      end

    end
  end
end
