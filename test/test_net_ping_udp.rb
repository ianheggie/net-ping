########################################################################
# test_net_ping_udp.rb
#
# Test case for the Net::Ping::UDP class. This should be run via the
# 'test' or 'test:udp' Rake tasks.
#
# If someone could provide me a host where a udp ping actually
# works (with a service check), I would appreciate it. :)
########################################################################
require 'test-unit'
require 'net/ping/udp'
require File.expand_path('../test_helper.rb', __FILE__)

class TC_Net_Ping_UDP < Test::Unit::TestCase
  def setup
    Net::Ping::UDP.service_check = false
    @host = '127.0.0.1'
    @udp  = Net::Ping::UDP.new(@host)
    @udp_unused_port  = Net::Ping::UDP.new(@host, TestHelper.blackhole_port)
    @blackhole         = Net::Ping::UDP.new(TestHelper.blackhole_ip, TestHelper.blackhole_port)
    @unreachable_host  = TestHelper.unreachable_host && Net::Ping::UDP.new(TestHelper.unreachable_host, TestHelper.blackhole_port)
    @unreachable_route = TestHelper.unreachable_route && Net::Ping::UDP.new(TestHelper.unreachable_route, TestHelper.blackhole_port)
  end

  test "ping basic functionality" do
    assert_respond_to(@udp, :ping)
    assert_nothing_raised{ @udp.ping }
  end

  test "ping accepts a host as an argument" do
    assert_nothing_raised{ @udp.ping(@host) }
  end

  test "ping? is an alias for ping" do
    assert_respond_to(@udp, :ping?)
    assert_alias_method(@udp, :ping?, :ping)
  end

  test "pingecho is an alias for ping" do
    assert_respond_to(@udp, :pingecho)
    assert_alias_method(@udp, :pingecho, :ping)
  end

  test "a successful udp ping returns true" do
    assert_true(@udp.ping?)
  end

  test "a successful udp ping sets response_data" do
    echo_cmd = File.expand_path('../udp_echo.rb', __FILE__)
    echo_process = IO.popen("ruby #{echo_cmd}", 'r')
    port = echo_process.gets.to_i
    @udp.port = port
    @udp.ping
    echo_process.close
    assert_kind_of(String, @udp.response_data)
    assert_not_equal('', @udp.response_data)
    assert_equal(@udp.data, @udp.response_data)
  end


  test "bind basic functionality" do
    assert_respond_to(@udp, :bind)
    assert_nothing_raised{ @udp.bind('127.0.0.1', 80) }
  end
   
  test "duration basic functionality" do
    assert_nothing_raised{ @udp.ping }
    assert_respond_to(@udp, :duration)
    assert_kind_of(Float, @udp.duration)
  end

  test "host basic functionality" do
    assert_respond_to(@udp, :host)
    assert_respond_to(@udp, :host=)
    assert_equal('127.0.0.1', @udp.host)
  end

  test "port basic functionality" do
    assert_respond_to(@udp, :port)
    assert_respond_to(@udp, :port=)
    assert_equal(7, @udp.port)
  end

  test "timeout basic functionality" do
    assert_respond_to(@udp, :timeout)
    assert_respond_to(@udp, :timeout=)
  end

  test "timeout default value is five" do
    assert_equal(5, @udp.timeout)
  end

  test "exception basic functionality" do
    assert_respond_to(@udp, :exception)
  end

  test "the exception attribute returns nil if the ping is successful" do
    assert_true(@udp.ping?)
    assert_nil(@udp.exception)
  end

  test "the exception attribute is not nil if the ping is unsuccessful" do
    assert_false(@udp.ping?('www.ruby-lang.org'))
    assert_not_nil(@udp.exception)
  end

  test "warning basic functionality" do
    assert_respond_to(@udp, :warning)
  end

  test "the warning attribute returns nil if the ping is successful" do
    assert_true(@udp.ping?)
    assert_nil(@udp.warning)
  end
   
  test "service_check basic functionality" do
    assert_respond_to(Net::Ping::UDP, :service_check)
    assert_respond_to(Net::Ping::UDP, :service_check=)
  end

  test "service_check attribute has been set to false" do
    assert_false(Net::Ping::UDP.service_check)
  end
   
  test "service_check getter method does not accept arguments" do
    assert_raise(ArgumentError){ Net::Ping::UDP.service_check(1) }
  end

  test "service_check setter method only accepts boolean arguments" do
    assert_raise(ArgumentError){ Net::Ping::UDP.service_check = 1 }
  end

  def test_ping_service_check_true_on_open_port
    msg = "checks localhost port #{@udp.port} is alive +this test will fail if that port is not open on this system+"
    Ping::UDP.service_check = true
    res = @udp.ping?
    assert_true(res, msg + ", exception = #{@udp.exception}")
  end

  def test_ping_service_check_true_on_closed_port
    msg = "checks localhost port #{@udp_unused_port.port} is NOT alive +this test will fail if that port IS open on this system+"
    Ping::UDP.service_check = true
    res = @udp_unused_port.ping?
    assert_false(res, msg + ", exception = #{@udp_unused_port.exception}")
  end

  def test_ping_service_check_false_on_closed_port
    msg = "checks localhost port #{@udp_unused_port.port}, but should return true even if it is closed"
    res = @udp_unused_port.ping?
    assert_true(res, msg + ", exception = #{@udp_unused_port.exception}")
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



  def teardown
    @host = nil
    @udp  = nil
  end
end
