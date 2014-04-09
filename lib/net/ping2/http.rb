require 'net/ping2/base'
require 'net/http'
require 'net/https'
require 'uri'
require 'open-uri'

# Force non-blocking Socket.getaddrinfo on Unix systems. Do not use on
# Windows because it (ironically) causes blocking problems.
unless File::ALT_SEPARATOR or RUBY_VERSION >= "1.9.3"
  require 'resolv-replace'
end

# The Net module serves as a namespace only.
module Net
  module Ping2

    # The Net::Ping2::HTTP class encapsulates methods for HTTP pings.
    class HTTP < Base

      # The port to ping. Defaults to port 80.
      #
      attr_accessor :port

      # By default an http ping will follow a redirect and give you the result
      # of the final URI.  If this value is set to false, then it will not
      # follow a redirect and will return false immediately on a redirect.
      #
      attr_accessor :follow_redirect

      # The maximum number of redirects allowed. The default is 5.
      attr_accessor :redirect_limit

      # The user agent used for the HTTP request. The default is 'net-ping2'.
      attr_accessor :user_agent

      # OpenSSL certificate verification mode. The default is VERIFY_NONE.
      attr_accessor :ssl_verify_mode

      # Use GET request instead HEAD. The default is false.
      attr_accessor :get_request

      # was this ping proxied?
      attr_reader :proxied

      # For unsuccessful requests that return a server error, it is
      # useful to know the HTTP status code of the response.
      attr_reader :code

      # Creates and returns a new Net::Ping2::HTTP object.
      # The default port is 80,
      # The default timeout is 10 seconds.
      #
      def initialize(options = {})
        @follow_redirect = true
        @redirect_limit = 5
        @ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
        @get_request = false
        @port = 80
        @port = URI.parse(options[:host]).port if options[:host]
        #@code = nil
        @user_agent = 'net-ping2'
        super(options)
      end

      # Looks for an HTTP response from the URI passed to the constructor.
      # If the result is a kind of Net::HTTPSuccess then the ping was
      # successful and true is returned.  Otherwise, false is returned
      # and the Net::Ping2::HTTP#exception method should contain a string
      # indicating what went wrong.
      #
      # If the HTTP#follow_redirect accessor is set to true (which it is
      # by default) and a redirect occurs during the ping, then the
      # HTTP#warning attribute is set to the redirect message, but the
      # return result is still true. If it's set to false then a redirect
      # response is considered a failed ping.
      #
      # If no file or path is specified in the URI, then '/' is assumed.
      # If no scheme is present in the URI, then 'http' is assumed.
      #
      def ping(host = nil, options = {})

        super(host, options)

        # See https://bugs.ruby-lang.org/issues/8645
        url = host || @host
        if url =~ %r{^//}
          url = "http:#{url}"
        elsif url !~ %r{^https?://}
          url = "url://#{url}"
        end
        uri = URI.parse(url)

        # A port provided here overrides anything provided in constructor
        port = options[:port]
        port ||= uri.port if host
        port ||= @port

        timeout = options[:timeout] || @timeout

        start_time = Time.now

        http_response = do_ping(uri, port, timeout)

        if http_response.is_a?(Net::HTTPSuccess)
          set_response(http_response)
          @success = true
        elsif redirect?(http_response) # Check code, HTTPRedirection does not always work
          if @follow_redirect
            @warning = http_response.message
            rlimit = 0

            while redirect?(http_response)
              if rlimit >= redirect_limit
                @exception = "Redirect limit exceeded"
                break
              end
              redirect = URI.parse(http_response['location'])
              redirect = uri + redirect if redirect.relative?
              http_response = do_ping(redirect, port, timeout)
              rlimit += 1
            end

            if http_response.is_a?(Net::HTTPSuccess)
              set_response(http_response)
              @success = true
            else
              @warning = nil
              @exception ||= http_response.message
            end

          else
            @exception = http_response.message
          end
        else
          @exception ||= http_response.message
        end

        # There is no duration if the ping failed
        @duration = Time.now - start_time if @success

        @success
      end

      alias follow_redirect? follow_redirect
      alias proxied? proxied

      protected

      def clear_results
        super()
        @proxied = @code = nil
      end

      private

      def redirect?(http_response)
        http_response && http_response.code.to_i >= 300 && http_response.code.to_i < 400
      end

      def do_ping(uri, port, timeout)
        http_response = nil
        proxy = uri.find_proxy || URI.parse("")
        uri_path = uri.path.empty? ? '/' : uri.path
        headers = {}
        headers["User-Agent"] = user_agent if user_agent
        begin
          http = Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password).new(uri.host, port)
          http.read_timeout = timeout
          http.open_timeout = timeout
          @proxied = http.proxy?
          if @get_request == true
            request = Net::HTTP::Get.new(uri_path)
          else
            request = Net::HTTP::Head.new(uri_path)
          end

          if uri.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = @ssl_verify_mode
          end
          http_response = Timeout.timeout(timeout) do
            http.start { |h| h.request(request) }
          end
        rescue Exception => err
          @exception = err.message
        ensure
          http.open_timeout = 999  # DEBUG
        end
        @code = http_response.code if http_response
        http_response
      end


      def set_response(http_response)
        if @get_request
          @response = http_response.body
        else
          @response = "HTTP#{http_response.http_version ? ('/' << http_response.http_version) : ''} #{http_response.code} #{http_response.message}\n"
          http_response.header.each do |key, value|
            @response << "#{key}: #{value}\n"
          end
        end
      end

    end
  end
end
