= Description
   A simple Ruby interface to the 'ping' command.

= Synopsis
   require 'net/ping'
   include Net

   Net::Ping2::TCP.service_check = true

   pt = Net::Ping2::TCP.new(host)
   pu = Net::Ping2::UDP.new(host)
   pe = Net::Ping2::External.new(host)
   ph = Net::Ping2::HTTP.new(uri)

   if pt.ping
      puts "TCP ping successful"
   else
      puts "TCP ping unsuccessful: " +  pt.exception
   end

   if pu.ping
      puts "UDP ping successful"
   else
      puts "UDP ping unsuccessful: " +  pu.exception
   end

   if pe.ping
      puts "External ping successful"
   else
      puts "External ping unsuccessful: " +  pe.exception
   end

   if ph.ping?
      puts "HTTP ping successful"
   else
      puts "HTTP ping unsuccessful: " + ph.exception
   end

= Ping Classes
   * Net::Ping2::TCP
   * Net::Ping2::UDP
   * Net::Ping2::External
   * Net::Ping2::HTTP
   * Net::Ping2::ICMP
   * Net::Ping2::WMI
   * Net::Ping2::LDAP

   All Ping2 classes are children of the Ping2 parent class (which should
   never be instantiated directly).

   The Net::Ping2::ICMP class requires root/administrative privileges.

   The Net::Ping2::WMI class only works on MS Windows.

== Net::Ping2
Net::Ping2.new(host=nil, port=7, timeout=5)
   Creates and returns a new Ping2 object.  If the host is not specified
   in the constructor then it must be specified in the ping method.

== Net::Ping2::TCP
Ping2::TCP.service_check
   Returns the setting for how ECONNREFUSED is handled. By default, this is
   set to false, i.e. an ECONNREFUSED error is considered a failed ping.

Ping2::TCP.service_check=(bool)
   Sets the behavior for how ECONNREFUSED is handled. By default, this is
   set to false, i.e. an ECONNREFUSED error is considered a failed ping.

Ping2::TCP#ping(host=nil)
   Attempts to open a connection using TCPSocket with a +host+ specified
   either here or in the constructor.  A successful open means the ping was
   successful and true is returned.  Otherwise, false is returned.

== Net::Ping2::UDP
Ping2::UDP#ping
   Attempts to open a connection using UDPSocket and sends the value of
   Net::Ping2::UDP#data as a string across the socket.  If the return string matches,
   then the ping was successful and true is returned.  Otherwise, false is
   returned.
	
Ping2::UDP#data
   Returns the string that is sent across the UDP socket.
	
Ping2::UDP#data=(string)
   Sets the string that is sent across the UDP socket.  The default is "ping".
   Note that the +string+ cannot be larger than MAX_DATA (64 characters).

== Net::Ping2::External
Ping2::External#ping
   Uses the 'open3' module and calls your system's local 'ping' command with
   various options, depending on platform.  If nothing is sent to stderr, the
   ping was successful and true is returned.  Otherwise, false is returned.

   The MS Windows platform requires the 'win32-open3' package.
	
== Net::Ping2::HTTP
Ping2::HTTP.new(uri=nil, port=80, timeout=5)
   Identical to Net::Ping2.new except that, instead of a host, the first
   argument is a URI.
	
Ping2::HTTP#ping
   Checks for a response against +uri+.  As long as kind of Net::HTTPSuccess
   response is returned, the ping is successful and true is returned.
   Otherwise, false is returned and Net::Ping2::HTTP#exception is set to the error
   message.

   Note that redirects are automatically followed unless the
   Net::Ping2::HTTP#follow_redirects method is set to false.

Ping2::HTTP#follow_redirect
   Indicates whether or not a redirect should be followed in a ping attempt.
   By default this is set to true.

Ping2::HTTP#follow_redirect=(bool)
   Sets whether or not a redirect should be followed in a ping attempt.  If
   set to false, then any redirect is considered a failed ping.

Ping2::HTTP#uri
   An alias for Net::Ping2::HTTP#host.
	
Ping2::HTTP#uri=(uri)
   An alias for Net::Ping2::HTTP#host=.

== Net::Ping2::ICMP
Ping2::ICMP#duration
   The time it took to ping the host.  Not a precise value but a good estimate.

== Net::Ping2::WMI
Ping2::WMI#ping(host, options={})
   Unlike other Ping2 classes, this method returns a PingStatus struct that
   contains various bits of information about the ping itself. The PingStatus
   struct is a wrapper for the Win32_PingStatus WMI class.

   In addition, you can pass options that will be interpreted as WQL parameters.

Ping2::WMI#ping?(host, options={})
   Returns whether or not the ping succeeded.

= Common Instance Methods
Ping#exception
   Returns the error string that was set if a ping call failed.  If an exception
   is raised, it is caught and stored in this attribute.  It is not raised in
   your code.
	
   This should be nil if the ping succeeded.

Ping#host
   Returns the host name that ping attempts will ping against.

Ping#host=(hostname)
   Sets the host name that ping attempts will ping against.

Ping#port
   Returns the port number that ping attempts will use.
	
Ping#port=(port)
   Set the port number to open socket connections on.  The default is 7 (or
   whatever your 'echo' port is set to).  Note that you can also specify a
   string, such as "http".

Ping#timeout
   Returns the amount of time before the timeout module raises a TimeoutError
   during connection attempts.  The default is 5 seconds.
	
Ping#timeout=(time)
   Sets the amount of time before the timeout module raises a TimeoutError.
   during connection attempts.
	
Ping#warning
   Returns a warning string that was returned during the ping attempt.  This
   typically occurs only in the Net::Ping2::External class, or the Net::Ping2::HTTP class
   if a redirect occurred.

== Notes
   If a host is down *IT IS CONSIDERED A FAILED PING*, and the 'no answer from
   +host+' text is assigned to the 'exception' attribute.  You may disagree with
   this behavior, in which case you need merely check the exception attribute
   against a regex as a simple workaround.

== Pre-emptive FAQ
   Q: "Why don't you return exceptions if a connection fails?"

   A: Because ping is only meant to return one of two things - success or
      failure. It's very simple. If you want to find out *why* the ping
      failed, you can check the 'exception' attribute.

   Q: "I know the host is alive, but a TCP or UDP ping tells me otherwise. What
      gives?"

   A: It's possible that the echo port has been disabled on the remote
      host for security reasons. Your best best is to specify a different port
      or to use Net::Ping2::ICMP or Net::Ping2::External instead.
      
      In the case of UDP pings, they are often actively refused. It may be
      more pragmatic to set Net::Ping2::UDP.service_check = false.

   Q: "Why does a TCP ping return false when I know it should return true?"

   A: By default ECONNREFUSED errors will return a value of false. This is
      contrary to what most other folks do for TCP pings. The problem with
      their philosophy is that you can get false positives if a firewall blocks
      the route to the host. The problem with my philosophy is that you can
      get false negatives if there is no firewall (or it's not blocking the
      route). Given the alternatives I chose the latter.

      You can always change the default behavior by using the +service_check+
      class method.
      
      A similar situation is true for UDP pings.

   Q: "Couldn't you use traceroute information to tell for sure?"

   A: I could but I won't so don't bug me about it. It's far more effort than
      it's worth. If you want something like that, please port the
      Net::Traceroute Perl module by Daniel Hagerty.

= Known Bugs
   You may see a test failure from the test_net_ping_tcp test case. You can
   ignore these.
   
   UDP pings may not work with older versions of Ruby 1.9.x.

   Please report any bugs on the project page at
   https://github.com/djberg96/net-ping

= Acknowledgements
   The Net::Ping2::ICMP#ping method is based largely on the identical method from
   the Net::Ping Perl module by Rob Brown. Much of the code was ported by
   Jos Backus on ruby-talk.

= Future Plans
   Add support for syn pings.

= License
   Artistic 2.0

= Copyright
   (C) 2003-2014 Daniel J. Berger, All Rights Reserved

= Warranty
   This package is provided "as is" and without any express or
   implied warranties, including, without limitation, the implied
   warranties of merchantability and fitness for a particular purpose.

= Author
   Daniel J. Berger
