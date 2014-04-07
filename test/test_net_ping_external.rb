#########################################################################
# test_net_ping_external.rb
#
# Test case for the Net::PingExternal class. Run this via the 'test' or
# 'test:external' rake task.
#
# WARNING: I've noticed that test failures will occur if you're using
# OpenDNS. This is apparently caused by them messing with upstream
# replies for advertising purposes.
#########################################################################
require 'test-unit'
require 'net/ping/external'
require File.expand_path('../test_helper.rb', __FILE__)

class TC_Net_Ping_External < Test::Unit::TestCase
  def setup
    @host        = 'localhost'
    @bogus       = 'foo.bar.baz'
    @pe          = Net::Ping::External.new(@host)
    @bad         = Net::Ping::External.new(@bogus)
    @blackhole         = Net::Ping::External.new(TestHelper.blackhole_ip)
    @unreachable_host  = TestHelper.unreachable_host && Net::Ping::External.new(TestHelper.unreachable_host)
    @unreachable_route = TestHelper.unreachable_route && Net::Ping::External.new(TestHelper.unreachable_route)
  end

  test "ping basic functionality" do
    assert_respond_to(@pe, :ping)
    assert_respond_to(@pe, :data)
    assert_respond_to(@pe, :response_data)
  end

  test "ping with no arguments" do
    assert_nothing_raised{ @pe.ping }
  end

  test "ping accepts a hostname" do
    assert_nothing_raised{ @pe.ping(@host) }
  end

  test "ping returns a boolean" do
    assert_boolean(@pe.ping)
    assert_boolean(@bad.ping)
  end

  test "ping? alias" do
    assert_respond_to(@pe, :ping?)
    assert_alias_method(@pe, :ping?, :ping)
  end

  test "pingecho alias" do
    assert_nothing_raised{ @pe.pingecho }
    assert_alias_method(@pe, :pingecho, :ping)
  end

  test "pinging a good host returns true" do
    assert_true(@pe.ping?)
  end

  test "pinging a bogus host returns false" do
    assert_false(@bad.ping?)
  end

  test "pinging a good host keeps response_data" do
    @pe.ping
    assert_kind_of(String, @pe.response_data)
    assert_not_equal('', @pe.response_data)
  end

  test "pinging a bogus host returns blank response_data" do
    @bad.ping
    assert_kind_of(String, @bad.response_data)
    assert_equal('', @bad.response_data)
  end

  test "duration basic functionality" do
    assert_nothing_raised{ @pe.ping }
    assert_respond_to(@pe, :duration)
    assert_kind_of(Float, @pe.duration)
  end

  test "duration is unset if a bad ping follows a good ping" do
    assert_nothing_raised{ @pe.ping }
    assert_not_nil(@pe.duration)
    assert_false(@pe.ping?(@bogus))
    assert_nil(@pe.duration)
  end

  test "host getter basic functionality" do
    assert_respond_to(@pe, :host)
    assert_equal('localhost', @pe.host)
  end

  test "host setter basic functionality" do
    assert_respond_to(@pe, :host=)
    assert_nothing_raised{ @pe.host = @bad }
    assert_equal(@bad, @pe.host)
  end

  test "port getter basic functionality" do
    assert_respond_to(@pe, :port)
    assert_equal(7, @pe.port)
  end

  test "port setter basic functionality" do
    assert_respond_to(@pe, :port=)
    assert_nothing_raised{ @pe.port = 90 }
    assert_equal(90, @pe.port)
  end

  test "timeout getter basic functionality" do
    assert_respond_to(@pe, :timeout)
    assert_equal(5, @pe.timeout)
  end

  test "timeout setter basic functionality" do
    assert_respond_to(@pe, :timeout=)
    assert_nothing_raised{ @pe.timeout = 30 }
    assert_equal(30, @pe.timeout)
  end

  test "exception method basic functionality" do
    assert_respond_to(@pe, :exception)
    assert_nil(@pe.exception)
  end

  test "pinging a bogus host stores exception data" do
    assert_nothing_raised{ @bad.ping? }
    assert_not_nil(@bad.exception)
  end

  test "pinging a good host results in no exception data" do
    assert_nothing_raised{ @pe.ping }
    assert_nil(@pe.exception)
  end

  test "warning basic functionality" do
    assert_respond_to(@pe, :warning)
    assert_nil(@pe.warning)
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

  test "pinging a blackhole returns after the timeout" do
    @blackhole.timeout = 1
    tolerance = 0.5
    start_time = Time.now
    res = @blackhole.ping
    elapsed = Time.now - start_time
    assert_true(elapsed < @blackhole.timeout + tolerance,
                'Expected elapsed (%1.1f) to be < timeout (%d) + tolerance (%1.1f), ping = %s, exception = %s' %
                    [elapsed, @blackhole.timeout, tolerance, res, @blackhole.exception.inspect])
  end

  test "pinging a blackhole waits for timeout" do
    # sanity check that it is a black hole we are testing
    @blackhole.timeout = 3
    tolerance = 0.5
    start_time = Time.now
    res = @blackhole.ping
    elapsed = Time.now - start_time
    assert_true(elapsed > @blackhole.timeout - tolerance,
                'Expected elapsed (%1.1f) to be > timeout (%d) - tolerance (%1.1f), ping = %s, exception = %s' %
                    [elapsed, @blackhole.timeout, tolerance, res, @blackhole.exception.inspect])
  end

  test "timing out causes expected result" do
    ext = Net::Ping::External.new('foo.bar.baz', nil, 1)
    start = Time.now
    assert_false(ext.ping?)
    elapsed = Time.now - start
    assert_true(elapsed < 2.5, "Actual elapsed: #{elapsed}")
    assert_not_nil(ext.exception)
  end

  def teardown
    @host        = nil
    @bogus       = nil
    @bcast_ip    = nil
    @pe          = nil
    @bad         = nil
    @unreachable = nil
  end
end
