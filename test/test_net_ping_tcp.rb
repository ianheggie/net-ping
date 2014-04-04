#####################################################################
# test_net_ping_tcp.rb
#
# Test case for the Net::PingTCP class. This test should be run via
# the 'test' or 'test:tcp' Rake task.
#####################################################################
require 'test-unit'
require 'net/ping/tcp'
include Net
require File.expand_path('../test_helper.rb', __FILE__)

class TC_PingTCP < Test::Unit::TestCase
  def setup
    Ping::TCP.service_check = false
    @host = 'localhost'
    @port = TestHelper.local_tcp_port
    @tcp  = Ping::TCP.new(@host, @port)
    @tcp_unused_port  = Ping::TCP.new(@host, TestHelper.blackhole_port)
    @blackhole         = Net::Ping::TCP.new(TestHelper.blackhole_ip, TestHelper.blackhole_port)
    @unreachable_host  = TestHelper.unreachable_host && Net::Ping::TCP.new(TestHelper.unreachable_host, TestHelper.blackhole_port)
    @unreachable_route = TestHelper.unreachable_route && Net::Ping::TCP.new(TestHelper.unreachable_route, TestHelper.blackhole_port)
  end

  def test_ping
    assert_respond_to(@tcp, :ping)
    assert_nothing_raised{ @tcp.ping }
    assert_nothing_raised{ @tcp.ping(@host) }
  end

  def test_ping_aliases
    assert_respond_to(@tcp, :ping?)
    assert_respond_to(@tcp, :pingecho)
    assert_nothing_raised{ @tcp.ping? }
    assert_nothing_raised{ @tcp.ping?(@host) }
    assert_nothing_raised{ @tcp.pingecho }
    assert_nothing_raised{ @tcp.pingecho(@host) }
  end

  # Decided to comment this out, pretty much always failed. Need a better test.
  #def test_ping_service_check_false
  #  msg = "+this test may fail depending on your network environment+"
  #  Ping::TCP.service_check = false
  #  @tcp = Ping::TCP.new('localhost')
  #  assert_false(@tcp.ping?, msg)
  #  assert_false(@tcp.exception.nil?, "Bad exception data")
  #end

  def test_ping_service_check_true_on_open_port
    msg = "checks localhost port #{@tcp.port} is alive +this test will fail if that port is not open on this system+"
    Ping::TCP.service_check = true
    res = @tcp.ping?
    assert_true(res, msg + ", exception = #{@tcp.exception}")
  end

  def test_ping_service_check_true_on_unused_port
    omit_if(ENV['EXCLUDE'].to_s =~ /TCP_SERVICE_CHECK_UNUSED_PORT_BUG/)
    msg = "checks localhost port #{@tcp_unused_port.port} is NOT alive +this test will fail if that port IS open on this system+"
    Ping::TCP.service_check = true
    res = @tcp_unused_port.ping?
    assert_false(res, msg + ", exception = #{@tcp_unused_port.exception}")
  end

  def test_ping_service_check_false_on_unused_port
    msg = "checks localhost port #{@tcp_unused_port.port}, but should return true even if it is closed"
    res = @tcp_unused_port.ping?
    assert_true(res, msg + ", exception = #{@tcp_unused_port.exception}")
  end

  def test_service_check
    assert_respond_to(Ping::TCP, :service_check)
    assert_respond_to(Ping::TCP, :service_check=)
  end

  # These will be removed eventually
  def test_service_check_aliases
    assert_respond_to(Ping::TCP, :econnrefused)
    assert_respond_to(Ping::TCP, :econnrefused=)
    assert_respond_to(Ping::TCP, :ecr)
    assert_respond_to(Ping::TCP, :ecr=)
  end

  def test_service_check_expected_errors
    assert_raises(ArgumentError){ Ping::TCP.service_check = "blah" }
  end

  # If the ping failed, the duration will be nil
  def test_duration
    assert_nothing_raised{ @tcp.ping }
    assert_respond_to(@tcp, :duration)
    omit_if(@tcp.duration.nil?, 'ping failed, skipping')
    assert_kind_of(Float, @tcp.duration)
  end

  def test_host
    assert_respond_to(@tcp, :host)
    assert_respond_to(@tcp, :host=)
    assert_equal(@host, @tcp.host)
  end

  def test_port
    assert_respond_to(@tcp, :port)
    assert_respond_to(@tcp, :port=)
    assert_equal(22, @tcp.port)
  end

  def test_timeout
    assert_respond_to(@tcp, :timeout)
    assert_respond_to(@tcp, :timeout=)
    assert_equal(5, @tcp.timeout)
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

  test "pinging a slow host returns without waiting for timeout" do
    echo_process, port = slow_server
    slow = Net::Ping::TCP.new('127.0.0.1', port)
    slow.timeout = 3
    tolerance = 0.9
    start_time = Time.now
    res = slow.ping
    elapsed = Time.now - start_time
    Process.kill('TERM', echo_process.pid)
    echo_process.close
    assert_true(elapsed < slow.timeout + tolerance,
                'Expected elapsed (%1.1f) to be < tolerance (%1.1f), ping = %s, exception = %s' %
                    [elapsed, tolerance, res, slow.exception.inspect])
  end

  def test_exception
    msg = "+this test may fail depending on your network environment+"
    assert_respond_to(@tcp, :exception)
    assert_nothing_raised{ @tcp.ping }
    assert_nil(@tcp.exception, msg)
  end

  def test_warning
    assert_respond_to(@tcp, :warning)
  end

  def teardown
    @host = nil
    @tcp  = nil
  end
end
