require 'open3'
require 'rbconfig'

require File.join(File.dirname(__FILE__), 'ping')

# The Net module serves as a namespace only.
module Net

  # The Ping::External class encapsulates methods for external (system) pings.
  class Ping::External < Ping

    ERR_MSG_SIZE = 4096

    # Pings the host using your system's ping utility and checks for any
    # errors or warnings. Returns true if successful, or false if not.
    #
    # If the ping failed then the Ping::External#exception method should
    # contain a string indicating what went wrong. If the ping succeeded then
    # the Ping::External#warning method may or may not contain a value.
    #
    def ping(host = @host)
      super(host)

      pcmd = ['ping']
      bool = false

      case RbConfig::CONFIG['host_os']
        when /linux/i
          pcmd += ['-c', '1', '-W', @timeout.to_s, host]
        when /aix/i
          pcmd += ['-c', '1', '-w', @timeout.to_s, host]
        when /bsd|osx|mach|darwin/i
          pcmd += ['-c', '1', '-t', @timeout.to_s, host]
        when /solaris|sunos/i
          pcmd += [host, @timeout.to_s]
        when /hpux/i
          pcmd += [host, '-n1', '-m', @timeout.to_s]
        when /win32|windows|msdos|mswin|cygwin|mingw/i
          #pcmd += ['-n', '1', '-w', (1000 * @timeout).to_i.to_s, host]
          pcmd += ['-n', '1', '-w', (@timeout * 1000).to_s, host]
        else
          pcmd += [host]
      end

      start_time = Time.now

      begin
        err = nil

        Open3.popen3(*pcmd) do |stdin, stdout, stderr, thread|
          stdin.close
          err = stderr.gets # Can't chomp yet, might be nil

          case thread.value.exitstatus
            when 0
              bool = true  # Success, at least one response.
              if err & err =~ /warning/i
                @warning = err.chomp
              end
            when 2
              bool = false # Transmission successful, no response.
              @exception = err.chomp if err
            else
              bool = false # An error occurred
              if err
                @exception = err.chomp
              else
                stdout.each_line do |line|
                  if line =~ /(timed out|could not find host|packet loss)/i
                    @exception = line.chomp
                    break
                  end
                end
              end
          end
        end
      rescue Exception => error
        @exception = error.message
      end

      # There is no duration if the ping failed
      @duration = Time.now - start_time if bool

      bool
    end

    # Runs a specified shell command in a separate thread.
    # If it exceeds the given timeout in seconds, kills it.
    # Returns a list of the form
    #
    #   [exit_code, err, response_data]
    #
    # which contains the exit code and any output sent by the command to stderr and stdout as a String.
    # Uses Kernel.select to wait up to the timeout length (in seconds)
    # before killing the process spawned by Open3.
    #
    def run_with_timeout(*command)
      err = nil
      response_data = ''
      exit_code = nil

      begin
        # Start task in another thread, which spawns a process
        stdin, stdout, stderr, thread = Open3.popen3(*command)
        # Get the pid of the spawned process
        pid = thread[:pid]
        start = Time.now

        while (Time.now - start) < timeout and thread.alive?
          begin
            err = stderr.read_nonblock(ERR_MSG_SIZE)
          rescue IO::WaitReadable
            IO.select([stderr], nil, nil, @timeout)
            next
          rescue EOFError
            # Command has completed, not really an error...
            if File::ALT_SEPARATOR
              response_data = stdout.read(ERR_MSG_SIZE)
            end
            break
          end
        end

        if thread.alive?
          # We need to kill the process, because killing the thread leaves
          # the process alive but detached, annoyingly enough.
          begin
            Process.kill("TERM", pid)
            err = "execution expired"
          rescue Errno::ESRCH
            # The process already exited, ignoring
          end
        end
        # Join the thread and get its exit status
        exit_code = thread.value.exitstatus
      ensure
        stdin.close if stdin
        stdout.close if stdout
        stderr.close if stderr
      end
      err ||= ''
      return [exit_code, err, response_data]
    end

    alias ping? ping
    alias pingecho ping
  end
end
