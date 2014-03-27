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
        when /linux|bsd|osx|mach|darwin/i
          pcmd += ['-c1', host]
        when /solaris|sunos/i
          pcmd += [host, '1']
        when /hpux/i
          pcmd += [host, '-n1']
        when /win32|windows|msdos|mswin|cygwin|mingw/i
          pcmd += ['-n', '1', host]
        else
          pcmd += [host]
      end

      start_time = Time.now

      begin
        exit_code, err = run_with_timeout(*pcmd)
        case exit_code
        when 0
          bool = true  # Success, at least one response.
          if err and err =~ /warning/i
            @warning = err.chomp
          end
        when 2
          bool = false # Transmission successful, no response.
          @exception = err.chomp
        else
          bool = false # An error occurred
          @exception = err.chomp
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
    #   [exit_code, err]
    #
    # which contains any output sent by the command to stderr as a String.
    # Uses Kernel.select to wait up to the timeout length (in seconds)
    # before killing the process spawned by Open3.
    #
    def run_with_timeout(*command)
      err = nil
      exit_code = nil

      begin
        # Start task in another thread, which spawns a process
        stdin, stdout, stderr, thread = Open3.popen3(*command)
        # Get the pid of the spawned process
        pid = thread[:pid]
        start = Time.now

        while (Time.now - start) < timeout and thread.alive?
          begin
            if File::ALT_SEPARATOR
              err = stderr.read(ERR_MSG_SIZE)
            else
              err = stderr.read_nonblock(ERR_MSG_SIZE)
            end
          rescue IO::WaitReadable
            IO.select([stderr], nil, nil, @timeout)
            next
          rescue EOFError
            # Command has completed, not really an error...
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
      return [exit_code, err]
    end

    alias ping? ping
    alias pingecho ping
  end
end
