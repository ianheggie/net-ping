# Net::Ping2

Net::Ping2 - Check a remote host for reachability, with optional service check.

** UNDER DEVELOPMENT **

This gem contains classes to test the reachability of remote hosts on a network.  A ping object is first created with optional parameters, a variable number of hosts may be pinged multiple times and then the connection is closed.

You may choose one of five different protocols to use for the ping. The "tcp" protocol is the default. Note that a live remote host may still fail to be pingable by one or more of these protocols. For example, www.microsoft.com is generally alive but not "icmp" pingable.

With the "tcp" protocol the ping() method attempts to establish a connection to the remote host's echo port. If the connection is successfully established, the remote host is considered reachable. No data is actually echoed. This protocol does not require any special privileges but has higher overhead than the "udp" and "icmp" protocols.

Specifying the "udp" protocol causes the ping() method to send a udp packet to the remote host's echo port. If the echoed packet is received from the remote host and the received packet contains the same data as the packet that was sent, the remote host is considered reachable. This protocol does not require any special privileges. It should be borne in mind that, for a udp ping, a host will be reported as unreachable if it is not running the appropriate echo service. For Unix-like systems see inetd(8) for more information.

If the "icmp" protocol is specified, the ping() method sends an icmp echo message to the remote host, which is what the UNIX ping program does. If the echoed message is received from the remote host and the echoed information is correct, the remote host is considered reachable. Specifying the "icmp" protocol requires that the program be run as root or that the program be setuid to root.

If the "external" protocol is specified, the ping() method attempts to use the `ping` command to ping the remote host. If the `ping` command if not installed on your system, specifying the "external" protocol will result in an error.

Originally based on code from djberg96's net-ping gem, the API and testing methodology has diverged.

* Continuous Integration testing - Linux and Windows tests are automatically run on public CI services, see links below;
* Ruby versions 1.8.7, 1.9.2, 1.9.3, 2.0 and 2.1 are supported along with JRuby 1.6.7+ and recent Rubinius, with some known issues;
* Set `service_check = true` to check the service on a port is open (like Perl's implementation, opposite to djbergs's implementation);
* service_check is an instance setting (like Perl's implementation, it is a class variable in djbergs's implementation);
* host and optionally port is an attribute of ping (and ping?), not of the creator;
* Net::Ping2.new(protocol) factory method is provided (similar to Perl).

[![Build Status](https://travis-ci.org/ianheggie/net-ping2.svg?branch=master)](https://travis-ci.org/ianheggie/net-ping2)
[![Windows Build status](https://ci.appveyor.com/api/projects/status/h18gcp0psjmhp0d6)](https://ci.appveyor.com/project/ianheggie/net-ping2)
[![Dependency Status](https://gemnasium.com/ianheggie/net-ping2.svg)](https://gemnasium.com/ianheggie/net-ping2)
[![Coverage Status](https://coveralls.io/repos/ianheggie/net-ping2/badge.png)](https://coveralls.io/r/ianheggie/net-ping2)

## Installation

Add this line to your application's Gemfile:

    gem 'net-ping2'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install net-ping2

## Usage


    require 'net/ping2'

    p = Net::Pings.new();

    host = 'www.github.com'
    puts "%s is %s" % [host, p.ping?($host) ? 'alive' : 'dead']

    p = Net::Ping->new("icmp");
    p->bind($my_addr); # Specify source interface of pings
    foreach $host (@host_array)
    {
    puts "$host is ";
    puts "NOT " unless p->ping($host, 2);
    puts "reachable.\n";
    sleep(1);
    }
    p->close();
    p = Net::Ping->new("tcp", 2);
    # Try connecting to the www port instead of the echo port
    p->port_number(scalar(getservbyname("http", "tcp")));
    while ($stop_time > time())
    {
    print "$host not reachable ", scalar(localtime()), "\n"
    unless p->ping($host);
    sleep(300);
    }
    undef(p);
    # Like tcp protocol, but with many hosts
    p = Net::Ping->new("syn");
    p->port_number(getservbyname("http", "tcp"));
    foreach $host (@host_array) {
    p->ping($host);
    }
    while (($host,$rtt,$ip) = p->ack) {
    print "HOST: $host [$ip] ACKed in $rtt seconds.\n";
    }
    # High precision syntax (requires Time::HiRes)
    p = Net::Ping->new();
    p->hires();
    ($ret, $duration, $ip) = p->ping($host, 5.5);
    printf("$host [ip: $ip] is alive (packet return time: %.2f ms)\n", 1000 * $duration)
    if $ret;
    p->close();
    # For backward compatibility
    print "$host is alive.\n" if pingecho($host);

## Notes

Please read the documentation under the 'doc' directory. Especially pay
attention to the documentation pertaining to ECONNREFUSED and TCP pings.

Also note the documentation regarding down hosts.

## Prerequisites and Known Issues

See the travis-ci tests for versions of ruby currently tested against. Not all features are supported on all rubies.

### UDP
* Older versions of Ruby 1.9.x may not work with UDP pings.
* Older versions of JRuby will return false positives in UDP pings
because of an incorrect error class being raised. See JRuby-4896.
* Jruby hangs if UDP ping doesn't receive a return packet. See JRuby-6974.
### External
* JRuby 1.6.7 or later is required for external pings because of a bug
in earlier versions with open3 and stream handling.
### ICMP
* ICMP pings will not work with JRuby without some sort of third-party
library support for raw sockets in Java, such as RockSaw.
### TCP
* TCP pings are not supported under JRuby: they fail with Errno::ECONNREFUSED.

## License

Artistic 2.0

## Contributing

1. Fork it ( http://github.com/ianheggie/net-ping2/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request, including tests will earn extra favour!

See []()

## More documentation
If you installed this library via Rubygems, you can view the inline
documentation via ri or fire up 'gem server', and point your browser at
http://localhost:8808.

## Authors
* Daniel J. Berger - net-ping gem
* Ian Heggie - net-ping2 variation

