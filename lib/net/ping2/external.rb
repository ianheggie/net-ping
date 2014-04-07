require 'open3'
require 'rbconfig'

require 'net/ping2/base'

# The Net module serves as a namespace only.
module Net
  module Ping2

    # The Net::Ping2::External class encapsulates methods for external (system) pings.
    class External < Base

      ERR_MSG_SIZE = 4096

      # Pings the host using your system's ping utility and checks for any
      # errors or warnings. Returns true if successful, or false if not.
      #
      # If the ping failed then the Net::Ping2::External#exception method should
      # contain a string indicating what went wrong. If the ping succeeded then
      # the Net::Ping2::External#warning method may or may not contain a value.
      #
      def ping(host = @host, options = {})
        host ||= @host
        super(host, options)

        timeout = options[:timeout] || @timeout

        pcmd = ['ping']
        @success = false
        @response = ''


        case RbConfig::CONFIG['host_os']
          when /linux/i
            pcmd += ['-c', '1', '-W', timeout.to_s, host]
          when /aix/i
            pcmd += ['-c', '1', '-w', timeout.to_s, host]
          when /bsd|osx|mach|darwin/i
            pcmd += ['-c', '1', '-t', timeout.to_s, host]
          when /solaris|sunos/i
            pcmd += [host, timeout.to_s]
          when /hpux/i
            pcmd += [host, '-n1', '-m', timeout.to_s]
          when /win32|windows|msdos|mswin|cygwin|mingw/i
            pcmd += ['-n', '1', '-w', (timeout * 1000).to_i.to_s, host]
          else
            pcmd += [host]
        end

        start_time = Time.now

        begin
          err = nil

          Open3.popen3(*pcmd) do |stdin, stdout, stderr, thread|
            stdin.close
            err = stderr.gets # Can't chomp yet, might be nil
            @response = stdout.read
            if thread
              if thread.value.exitstatus == 0
                @success = true # Success, at least one response.
                if err & err =~ /warning/i
                  @warning = err.chomp
                end
              else
                set_exception(err)
              end
            elsif @response =~ /\D0+% (packet )?loss/
              # Linux / windows loss percentage
              @success = true
            elsif @response =~ /\D(\d*[1-9]\d*% (packet )?loss)/
              @exception = "#{$1}"
            else
              set_exception(err)
              @exception ||= 'exitstatus could not be checked and stdout did not contain a recognisable loss percentage'
            end
          end
        rescue Exception => error
          @exception = error.message
        end

        # There is no duration if the ping failed
        @duration = @success ? Time.now - start_time : nil
      end

      private

      def set_exception(err)
        if err
          @exception = err.chomp
          if err =~ /warning/i
            @warning = @exception
          end
        else
          @response.split("\n").each do |line|
            if line =~ /warning/i
              @warning = line.chomp
            end
            if line =~ /(timed out|could not find host|packet loss|unknown host)/i
              @exception = line.chomp
              break
            end
          end
        end
      end

    end
  end
end
