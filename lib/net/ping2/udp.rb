require 'socket'
require 'net/ping2/base'

# The Net module serves as a namespace only.
module Net
  module Ping2

    # The Net::Ping2::UDP class encapsulates methods for UDP pings.
    # noinspection RubyTooManyInstanceVariablesInspection
    class UDP < Base

      # The port to ping. Defaults to port 7 (echo).
      #
      attr_reader :port

      def port=(port)
        @service_check = true
        @port = port
        @data_must_match = (port == 7) # only check match if using the echo port
      end

      # Returns if the service on that port is checked.
      # If false then Errno::ECONNREFUSED or Errno::ECONNRESET is considered a success
      #
      attr_accessor :service_check

      # Returns if the service on that port is checked.
      # If false then Errno::ECONNREFUSED or Errno::ECONNRESET is considered a success
      #
      attr_accessor :data_must_match

      # The maximum data size that can be sent in a UDP ping.
      MAX_DATA = 64

      # The data to send to the remote host. By default this is "ping\n".
      # This should be MAX_DATA size characters or less.
      #
      attr_reader :data

      def self.not_available_message
        # noinspection RubyResolve
        return 'JRUBY-6974 - Timeout.timeout not working using UDPSocket (needs non-blocking socket rework)' if defined? JRUBY_VERSION
      end

      # Creates and returns a new Net::Ping2:: object.  This is effectively
      # identical to its superclass constructor.
      #

      # Creates and returns a new Net::Ping2::UDP object.
      # The default timeout is 10 seconds.
      # service_check is false by default, unless port is explicitly set.
      def initialize(options = {})
        @port = 7
        @service_check = false
        @data_must_match = true
        @data = "net-ping2\n"
        @timeout = 10
        @bind_host = nil
        @bind_port = nil
        super(options)
      end

      # Sets the data string sent to the remote host. This value cannot have
      # a size greater than MAX_DATA.
      #
      def data=(string)
        if string.size > MAX_DATA
          err = "cannot set data string larger than #{MAX_DATA} characters"
          raise ArgumentError, err
        end

        @data = string
      end

      # Associates the local end of the UDP connection with the given +host+
      # and +port+. This is essentially a wrapper for UDPSocket#bind.
      #
      def bind(host, port)
        @bind_host = host
        @bind_port = port
      end

      # Sends a simple text string to the host and checks the return string. If
      # the string sent and the string returned are a match then the ping was
      # successful and true is returned. Otherwise, false is returned.
      #
      def ping(host = @host, options = {})
        super(host, options)

        opt1 = (options.key?(:port) ? {:service_check => true, :data_must_match => (options[:port] == 7)} : {})
        opt2 = {
            :service_check => @service_check,
            :timeout => @timeout,
            :bind_host => @bind_host,
            :bind_port => @bind_port,
            :data_must_match => @data_must_match,
            :data => @data,
            :port => @port}
        options = opt1.merge(opt2).merge(options)

        @success = false
        udp = UDPSocket.open
        @response = []

        if options[:bind_host]
          udp.bind(options[:bind_host], options[:bind_port])
        end

        start_time = Time.now

        begin
          Timeout.timeout(options[:timeout]) {
            udp.connect(host, options[:port])
            udp.send(options[:data], 0)
            @response = udp.recvfrom(MAX_DATA)
          }
        rescue Errno::ECONNREFUSED, Errno::ECONNRESET => err
          if options[:service_check]
            @exception = err
          else
            @success = true
          end
        rescue Exception => err
          @exception = err
        else
          if @response[0] == options[:data] || !options[:data_must_match]
            @success = true
          end
        ensure
          udp.close if udp
        end

        # There is no duration if the ping failed
        @duration = Time.now - start_time if @success

        @success
      end

    end
  end
end
