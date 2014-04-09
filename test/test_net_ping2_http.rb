#################################################################################
# test_net_ping_http.rb
#
# Test case for the Net::PingHTTP class. This should be run via the 'test' or
# 'test:http' Rake task.
#################################################################################
require File.expand_path('../test_helper.rb', __FILE__)
require 'fakeweb'
require 'net/ping2/http'

class TestNetPing2HTTP < Test::Unit::TestCase
  #extend TestHelper

  if Net::Ping2::HTTP.available?

    def setup
      extend TestHelper
      ENV['http_proxy'] = ENV['https_proxy'] = ENV['no_proxy'] = nil
      @uri = 'http://www.google.com/index.html'
      @bad = bad_hostname_uri
      @bad_gateway = 'http://http502.com'
      @uri_https = 'https://encrypted.google.com'
      @proxy = 'http://username:password@proxy:3128'
      @redirect = 'http://jigsaw.w3.org/HTTP/300/302.html'
      FakeWeb.allow_net_connect = allow_net_connect()
      FakeWeb.register_uri(:head, 'http://' << LOCALHOST_IP, :body => 'PONG')

      FakeWeb.register_uri(:get, @uri, :body => 'PONG')
      FakeWeb.register_uri(:head, @uri, :body => 'PONG')
      FakeWeb.register_uri(:head, @uri_https, :body => 'PONG')
      FakeWeb.register_uri(:get, @uri_https, :body => 'PONG')
      FakeWeb.register_uri(:head, @redirect,
                           :body => 'A REDIRECT',
                           :location => @uri,
                           :status => %w(302 Found))

      FakeWeb.register_uri(:any, @bad, :exception => SocketError)
      FakeWeb.register_uri(:head, @bad_gateway,
                           :body => '',
                           :status => ['502', 'Bad Gateway'])


      @ping = Net::Ping2::HTTP.new(:timeout => 30, :port => 80)

      @ping = Net::Ping2::HTTP.new()
      @ping_with_host = Net::Ping2::HTTP.new(:host => LOCALHOST_IP)

    end

    def teardown
      FakeWeb.clean_registry
      FakeWeb.allow_net_connect = true
    end

    check_ping_arguments
    check_class_methods
    check_attr_readers :proxied, :code
    check_attr_accessors :port, :follow_redirect, :redirect_limit, :user_agent, :ssl_verify_mode, :get_request
    check_defaults :timeout => 5, :proxied => nil, :code => nil, :follow_redirect => true, :redirect_limit => 5,
                   :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE, :get_request => false, :user_agent => 'net-ping2'

    check_good_host_behaviour
    check_bad_hosts_behaviour(self.bad_hosts)

    check_thread_safety

    test 'redirect_limit defaults to 5' do
      assert_equal(5, @ping.redirect_limit)
    end

    test 'redirects succeed by default' do
      res = @ping.ping?(@redirect)
      assert_true(res, "ping returned #{res}, exception = #{@ping.exception.inspect}")
    end

    test 'redirect fail if follow_redirect is set to false' do
      @ping.follow_redirect = false
      assert_false(@ping.ping?(@redirect))
    end

    test 'ping with redirect limit set to zero fails' do
      @ping.redirect_limit = 0
      assert_false(@ping.ping?(@redirect))
      assert_equal('Redirect limit exceeded', @ping.exception)
    end

    test 'ping with get_request=true option' do
      @ping.get_request = true
      res = @ping.ping?(@uri)
      assert_true(res, 'exception = %s' % @ping.exception)
    end

    test 'ping with http proxy and get_request=true' do
      ENV['http_proxy'] = 'http://proxymoxie:3128'
      @ping.get_request = true
      assert_true(@ping.ping?(@uri))
      assert_true(@ping.proxied)
    end

    test 'ping with https proxy and get_request=true' do
      ENV['http_proxy'] = 'https://proxymoxie:3128'
      @ping.get_request = true
      assert_true(@ping.ping?(@uri))
      assert_true(@ping.proxied?)
    end

    test 'ping with no_proxy and get_request=true' do
      ENV['no_proxy'] = 'google.com'
      @ping.get_request = true
      assert_true(@ping.ping?(@uri))
      assert_false(@ping.proxied)
    end

=begin


    test 'ping requires host argument' do
      #noinspection RubyArgCount
      assert_raise(ArgumentError) { @ping.ping }
    end

    test 'ping returns a boolean value' do
      assert_boolean(@ping.ping?(@uri))
      assert_boolean(@ping.ping?(@bad))
    end

    test 'ping should succeed for a valid website' do
      assert_true(@ping.ping?(@uri))
    end

    bad_uris.each do |name, uri|
      test "ping should fail for #{name}" do
        assert_false(@ping.ping?(uri, 3))
      end

      test "pinging #{name} returns within timeout" do
        start_time = Time.now
        res = @ping.ping?(uri, 1)
        elapsed = Time.now - start_time
        assert_true(elapsed < 1.5,
                    'Expected elapsed (%1.1f) to be < 1.5, ping returned %s with exception = %s' %
                        [elapsed, res, @ping.exception.inspect])
      end

    end

    test 'duration returns a float value on a successful ping' do
      assert_true(@ping.ping?(@uri))
      assert_kind_of(Float, @ping.duration)
    end

    test 'duration is nil on an unsuccessful ping' do
      assert_false(@ping.ping?(@bad))
      assert_nil(@ping.duration)
    end

    test 'port attribute expected value' do
      assert_equal(80, @ping.port)
    end

    test 'timeout attribute expected values' do
      assert_equal(30, @ping.timeout)
    end

    test 'pinging a black hole waits for timeout' do
      omit_unless blackhole_uri
      start_time = Time.now
      res = @ping.ping?(blackhole_uri, 1)
      elapsed = Time.now - start_time
      assert_true(elapsed > 0.5,
                  'Expected elapsed (%1.1f) to be > 0.5, ping returned %s, exception = %s' %
                      [elapsed, res, @ping.exception.inspect])
    end

    def slow_server
      echo_cmd = File.expand_path('../slow_server.rb', __FILE__)
      echo_process = IO.popen('ruby %s' % echo_cmd, 'r')
      port = echo_process.gets.to_i
      slow = Net::Ping2::HTTP.new(1)
      [echo_process, port, slow, Time.now]
    end

    def stop_slow_server(echo_process)
      Process.kill('TERM', echo_process.pid)
      echo_process.close
    end

    test 'pinging a slow host returns after the timeout' do
      omit_if(ENV['EXCLUDE'].to_s =~ /HTTP_PING_DOES_NOT_TIMEOUT_BUG/, 'HTTP_PING_DOES_NOT_TIMEOUT_BUG excluded')
      echo_process, port, slow, start_time = slow_server
      res = slow.ping('http://127.0.0.1/', 1, port)
      elapsed = Time.now - start_time
      stop_slow_server(echo_process)
      assert_true(elapsed < 1.5,
                  'Expected elapsed (%1.1f) to be < 1.5, ping returned %s, exception = %s' %
                      [elapsed, res, slow.exception.inspect])
    end

    test 'pinging a slow host waits for timeout' do
      echo_process, port, slow, start_time = slow_server
      res = slow.ping('http://127.0.0.1/', 1, port)
      elapsed = Time.now - start_time
      stop_slow_server(echo_process)
      assert_true(elapsed > 0.5,
                  'Expected elapsed (%1.1f) to be > 0.5, ping = %s, exception = %s' %
                      [elapsed, res, slow.exception.inspect])
    end


    test 'exception attribute is nil if the ping is successful' do
      assert_true(@ping.ping?(@uri))
      assert_nil(@ping.exception)
    end

    test 'exception attribute is not nil if the ping is unsuccessful' do
      assert_false(@ping.ping?(@bad))
      assert_not_nil(@ping.exception)
    end

    test 'code attribute is set' do
      assert_true(@ping.ping?(@uri))
      assert_equal('200', @ping.code)
    end

    # be a good neighbour
    test 'user_agent defaults to net-ping2' do
      assert_equal('net-ping2', @ping.user_agent)
    end

    test 'ping with user agent' do
      @ping.user_agent = 'KDDI-CA32'
      assert_true(@ping.ping?(@uri))
    end



    test 'http 502 sets exception' do
      assert_false(@ping.ping?(@bad_gateway))
      assert_equal('Bad Gateway', @ping.exception)
    end

    test 'http 502 sets code' do
      assert_false(@ping.ping?(@bad_gateway))
      assert_equal('502', @ping.code)
    end

    test 'ping against https site works as expected' do
      res = @ping.ping?(@uri_https)
      assert_true(res, 'exception = %s' % @ping.exception)
    end


=end

  else
    def test_new_raises_exception
      assert_raise(NotImplementedError) { Net::Ping2::HTTP.new }
    end

    def tests_are_disabled
      omit('tests are disabled: ' + Net::Ping2::HTTP.not_available_message)
    end

  end


end
