#################################################################################
# test_net_ping_http.rb
#
# Test case for the Net::PingHTTP class. This should be run via the 'test' or
# 'test:http' Rake task.
#################################################################################
require 'test-unit'
require 'fakeweb'
require 'net/ping/http'
require File.expand_path('../test_helper.rb', __FILE__)

class TC_Net_Ping_HTTP < Test::Unit::TestCase
  def setup
    ENV['http_proxy'] = ENV['https_proxy'] = ENV['no_proxy'] = nil
    @uri = 'http://www.google.com/index.html'
    @uri_https = 'https://encrypted.google.com'
    @proxy = 'http://username:password@proxymoxie:3128'
    FakeWeb.allow_net_connect = TestHelper.allow_net_connect

    FakeWeb.register_uri(:get, @uri, :body => "PONG")
    FakeWeb.register_uri(:head, @uri, :body => "PONG")
    FakeWeb.register_uri(:head, @uri_https, :body => "PONG")
    FakeWeb.register_uri(:get, @uri_https, :body => "PONG")
    FakeWeb.register_uri(:head, "http://jigsaw.w3.org/HTTP/300/302.html",
                         :body => "PONG",
                         :location => "#{@uri}",
                         :status => ["302", "Found"])

    FakeWeb.register_uri(:any, 'http://www.blabfoobarurghxxxx.com', :exception => SocketError)
    FakeWeb.register_uri(:head, 'http://http502.com',
                         :body => "",
                         :status => ["502", "Bad Gateway"])


    @http = Net::Ping::HTTP.new(@uri, 80, 30)
    @bad  = Net::Ping::HTTP.new('http://www.blabfoobarurghxxxx.com') # One hopes not

    @blackhole         = Net::Ping::HTTP.new(TestHelper.blackhole_url)
    @unreachable_host  = TestHelper.unreachable_host_url && Net::Ping::HTTP.new(TestHelper.unreachable_host_url)
    @unreachable_route = TestHelper.unreachable_route_url && Net::Ping::HTTP.new(TestHelper.unreachable_route_url)
  end

  test 'ping basic functionality' do
    assert_respond_to(@http, :ping)
    assert_nothing_raised{ @http.ping }
  end

  test 'ping returns a boolean value' do
    assert_boolean(@http.ping?)
    assert_boolean(@bad.ping?)
  end


  test "ping returns with header in response_data" do
    assert_false(@http.get_request)
    @http.ping
    assert_kind_of(String, @http.response_data)
    assert_not_equal('', @http.response_data)
    assert_match(/^HTTP/, @http.response_data)
  end

  test "ping get_request returns with body in response_data" do
    @http.get_request = true
    @http.ping
    assert_kind_of(String, @http.response_data)
    assert_not_equal('', @http.response_data)
    assert_match('PONG', @http.response_data)
  end

  test "pinging a bogus host returns nil response_data" do
    @bad.ping
    assert_nil(@bad.response_data)
  end

  test 'ping? is an alias for ping' do
    assert_alias_method(@http, :ping?, :ping)
  end

  test 'pingecho is an alias for ping' do
    assert_alias_method(@http, :pingecho, :ping)
  end

  test 'ping should succeed for a valid website' do
    assert_true(@http.ping?)
  end

  test 'ping should fail for an invalid website' do
    assert_false(@bad.ping?)
  end

  test 'ping should fail for an unreachable website' do
    omit_unless(@unreachable_host)
    @unreachable_host.timeout = 3
    assert_false(@unreachable_host.ping?)
  end

  test 'ping should fail for a website on an unreachable route' do
    omit_unless(@unreachable_route)
    @unreachable_route.timeout = 3
    assert_false(@unreachable_route.ping?)
  end

  test 'ping should fail for a black hole' do
    @blackhole.timeout = 3
    assert_false(@blackhole.ping?)
  end

  test 'duration basic functionality' do
    assert_respond_to(@http, :duration)
    assert_nothing_raised{ @http.ping }
  end

  test 'duration returns a float value on a successful ping' do
    assert_true(@http.ping)
    assert_kind_of(Float, @http.duration)
  end

  test 'duration is nil on an unsuccessful ping' do
    assert_false(@bad.ping)
    assert_nil(@http.duration)
  end

  test 'host attribute basic functionality' do
    assert_respond_to(@http, :host)
    assert_respond_to(@http, :host=)
    assert_equal('http://www.google.com/index.html', @http.host)
  end

  test 'uri is an alias for host' do
    assert_alias_method(@http, :uri, :host)
    assert_alias_method(@http, :uri=, :host=)
  end

  test 'port attribute basic functionality' do
    assert_respond_to(@http, :port)
    assert_respond_to(@http, :port=)
  end

  test 'port attribute expected value' do
    assert_equal(80, @http.port)
  end

  test 'timeout attribute basic functionality' do
    assert_respond_to(@http, :timeout)
    assert_respond_to(@http, :timeout=)
  end

  test 'timeout attribute expected values' do
    assert_equal(30, @http.timeout)
    assert_equal(5, @bad.timeout)
  end

  test "pinging an unreachable host returns after the timeout" do
    omit_unless(@unreachable_host)
    @unreachable_host.timeout = 1
    tolerance = 0.5
    start_time = Time.now
    res = @unreachable_host.ping
    elapsed = Time.now - start_time
    assert_true(elapsed < @unreachable_host.timeout + tolerance,
                'Expected elapsed (%1.1f) to be < timeout (%d) + tolerance (%1.1f), ping = %s, exception = %s' %
                    [elapsed, @unreachable_host.timeout, tolerance, res, @unreachable_host.exception.inspect])
  end


  test "pinging a host on an unreacable network returns after the timeout" do
    omit_unless(@unreachable_route)
    @unreachable_route.timeout = 1
    tolerance = 0.5
    start_time = Time.now
    res = @unreachable_route.ping
    elapsed = Time.now - start_time
    assert_true(elapsed < @unreachable_route.timeout + tolerance,
                'Expected elapsed (%1.1f) to be < timeout (%d) + tolerance (%1.1f), ping = %s, exception = %s' %
                    [elapsed, @unreachable_route.timeout, tolerance, res, @unreachable_route.exception.inspect])
  end

  test "pinging a black hole returns after the timeout" do
    @blackhole.timeout = 1
    tolerance = 0.5
    start_time = Time.now
    res = @blackhole.ping
    elapsed = Time.now - start_time
    assert_true(elapsed < @blackhole.timeout + tolerance,
                'Expected elapsed (%1.1f) to be < timeout (%d) + tolerance (%1.1f), ping = %s, exception = %s' %
                    [elapsed, @blackhole.timeout, tolerance, res, @blackhole.exception.inspect])
  end

  test "pinging a black hole waits for timeout" do
    @blackhole.timeout = 3
    tolerance = 0.5
    start_time = Time.now
    res = @blackhole.ping
    elapsed = Time.now - start_time
    assert_true(elapsed > @blackhole.timeout - tolerance,
                'Expected elapsed (%1.1f) to be > timeout (%d) - tolerance (%1.1f), ping = %s, exception = %s' %
                    [elapsed, @blackhole.timeout, tolerance, res, @blackhole.exception.inspect])
  end

  def slow_server
    echo_cmd = File.expand_path('../slow_server.rb', __FILE__)
    echo_process = IO.popen('ruby %s' % echo_cmd, 'r')
    port = echo_process.gets.to_i
    [ echo_process, port ]
  end

  test "pinging a slow host returns after the timeout" do
    omit_if(ENV['EXCLUDE'].to_s =~ /HTTP_PING_DOES_NOT_TIMEOUT_BUG/, 'HTTP_PING_DOES_NOT_TIMEOUT_BUG excluded')
    echo_process, port = slow_server
    slow = Net::Ping::HTTP.new('http://127.0.0.1/', port)
    slow.timeout = 1
    tolerance = 0.5
    start_time = Time.now
    res = slow.ping
    elapsed = Time.now - start_time
    Process.kill('TERM', echo_process.pid)
    echo_process.close
    assert_true(elapsed < slow.timeout + tolerance,
                'Expected elapsed (%1.1f) to be < timeout (%d) + tolerance (%1.1f), ping = %s, exception = %s' %
                    [elapsed, slow.timeout, tolerance, res, slow.exception.inspect])
  end

  test "pinging a slow host waits for timeout" do
    echo_process, port = slow_server
    slow = Net::Ping::HTTP.new('http://127.0.0.1/', port)
    slow.timeout = 3
    tolerance = 0.5
    start_time = Time.now
    res= slow.ping
    elapsed = Time.now - start_time
    Process.kill('TERM', echo_process.pid)
    echo_process.close
    assert_true(elapsed > slow.timeout - tolerance,
                'Expected elapsed (%1.1f) to be > timeout (%d) - tolerance (%1.1f), ping = %s, exception = %s' %
                    [elapsed, slow.timeout, tolerance, res, slow.exception.inspect])
  end


  test 'exception attribute basic functionality' do
    assert_respond_to(@http, :exception)
    assert_nil(@http.exception)
  end

  test 'exception attribute is nil if the ping is successful' do
    assert_true(@http.ping)
    assert_nil(@http.exception)
  end

  test 'exception attribute is not nil if the ping is unsuccessful' do
    assert_false(@bad.ping)
    assert_not_nil(@bad.exception)
  end

  test 'warning attribute basic functionality' do
    assert_respond_to(@http, :warning)
    assert_nil(@http.warning)
  end

  test 'code attribute is set' do
    assert_true(@http.ping)
    assert_equal('200', @http.code)
  end

  test 'user_agent accessor is defined' do
    assert_respond_to(@http, :user_agent)
    assert_respond_to(@http, :user_agent=)
  end

  test 'user_agent defaults to nil' do
    assert_nil(@http.user_agent)
  end

  test 'ping with user agent' do
    @http.user_agent = "KDDI-CA32"
    assert_true(@http.ping)
  end

  test 'redirect_limit accessor is defined' do
    assert_respond_to(@http, :redirect_limit)
    assert_respond_to(@http, :redirect_limit=)
  end

  test 'redirect_limit defaults to 5' do
    assert_equal(5, @http.redirect_limit)
  end

  test 'redirects succeed by default' do
    @http = Net::Ping::HTTP.new("http://jigsaw.w3.org/HTTP/300/302.html")
    assert_true(@http.ping)
  end

  test 'redirect fail if follow_redirect is set to false' do
    @http = Net::Ping::HTTP.new("http://jigsaw.w3.org/HTTP/300/302.html")
    @http.follow_redirect = false
    assert_false(@http.ping)
  end

  test 'ping with redirect limit set to zero fails' do
    @http = Net::Ping::HTTP.new("http://jigsaw.w3.org/HTTP/300/302.html")
    @http.redirect_limit  = 0
    assert_false(@http.ping)
    assert_equal("Redirect limit exceeded", @http.exception)
  end

  test 'http 502 sets exception' do
    @http = Net::Ping::HTTP.new("http://http502.com")
    assert_false(@http.ping)
    assert_equal('Bad Gateway', @http.exception)
  end

  test 'http 502 sets code' do
    @http = Net::Ping::HTTP.new("http://http502.com")
    assert_false(@http.ping)
    assert_equal('502', @http.code)
  end

  test 'ping against https site defaults to port 443' do
    @http = Net::Ping::HTTP.new(@uri_https)
    assert_equal(443, @http.port)
  end

  test 'ping against https site works as expected' do
    @http = Net::Ping::HTTP.new(@uri_https)
    assert_true(@http.ping)
  end

  test 'ping with get option' do
    @http = Net::Ping::HTTP.new(@uri)
    @http.get_request = true
    assert_true(@http.ping)
  end

  test 'ping with http proxy' do
    ENV['http_proxy'] = "http://proxymoxie:3128"
    @http = Net::Ping::HTTP.new(@uri)
    @http.get_request = true
    assert_true(@http.ping)
    assert_true(@http.proxied)
  end

  test 'ping with https proxy' do
    ENV['https_proxy'] = "http://proxymoxie:3128"
    @http = Net::Ping::HTTP.new(@uri_https)
    @http.get_request = true
    assert_true(@http.ping)
    assert_true(@http.proxied)
  end

  test 'ping with no_proxy' do
    ENV['no_proxy'] = "google.com"
    @http = Net::Ping::HTTP.new(@uri)
    @http.get_request = true
    assert_true(@http.ping)
    assert_false(@http.proxied)
  end

  def teardown
    @uri  = nil
    @http = nil
  end
end
