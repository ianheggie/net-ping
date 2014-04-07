require 'socket'
require 'timeout'

# The Net module serves as a namespace only.
#
module Net
  module Ping2
    # The Base class serves as an abstract base class for all other Ping class
    # types. You should not instantiate this class directly.
    #
    class Base
      # The port to ping. This is set to the echo port (7) by default. The
      # Net::Ping2::HTTP class defaults to port 80.
      #
      #attr_accessor :port

      # The default host to ping.
      #
      attr_accessor :host

      # The maximum time a ping attempt is made, in seconds.
      attr_accessor :timeout

      # If a ping fails, this value is set to the exception or a string explaining that occurred which
      # what caused it to fail.
      #
      attr_reader :exception

      # This value is set if a ping succeeds, but some other condition arose
      # during the ping attempt which merits warning, e.g a redirect in the
      # case of Net::Ping2::HTTP#ping.
      #
      attr_reader :warning

      # The number of seconds (returned as a Float) that it took to ping
      # the host. This is not a precise value, but rather a good estimate
      # since there is a small amount of internal calculation that is added
      # to the overall time.
      #
      attr_reader :duration

      # The response from the server in whatever is the appropriate format for that protocol
      attr_reader :response

      # Boolean flag - true if the last ping succeeded
      attr_reader :success

      def self.not_available_message
        nil
      end

      def self.available?
        ENV['PING2_CLASSES'] == 'all' || !self.not_available_message
      end

      # The default constructor for the Net::Ping class.  Accepts an optional
      # hash of +options+. The default timeout is 5 seconds.
      #
      # The host, although optional in the constructor, must be specified at
      # some point before the Net::Ping#ping method is called, or else an
      # ArgumentError will be raised.
      #
      # Yields +self+ in block context.
      #
      # This class is not meant to be instantiated directly.
      # It should be called last in the subclass initialize method via a super(options) call.
      #
      def initialize(options = {})
        if msg = self.class.not_available_message
          if ENV['PING2_CLASSES'] == 'all'
            STDERR.puts "#{self.class.name}: Ignoring #{msg} since ENV['PING2_CLASSES'] == 'all'"
          else
            raise NotImplementedError.new(msg)
          end
        end
        @host = nil
        @timeout = 5
        # extract port first if set, as it often affects other settings
        if port = options.delete(:port)
          # extract port from options
          self.send("port=", port)
        end
        options.each do |key, value|
          self.send("#{key}=", value)
        end
        clear_results
        yield self if block_given?
      end

      # The default interface for the Net::Ping#ping method.  Each subclass
      # should call super() before continuing with their own implementation in
      # order to ensure that the @exception and @warning instance variables
      # are reset.
      #
      # If +host+ is nil here, then it will use the host specified in the
      # constructor.  If the +host+ is nil and there was no host specified
      # in the constructor then an ArgumentError is raised.
      #--
      # The @duration should be set in the subclass' ping method.
      #
      def ping(host = @host, options = {})
        raise ArgumentError, 'no host specified' unless host || @host
        raise ArgumentError, 'no timeout specified and default is nil' unless options[:timeout] || @timeout
        clear_results
      end

      # returns true or false
      def ping?(host = @host, options = {})
        !!ping(host, options)
      end

      alias_method :success?, :success

      protected

      def clear_results
        @success = false
        @duration = @exception = @response = @warning = nil
      end

    end
  end
end
