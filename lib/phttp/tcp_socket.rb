require "socket"

module PHTTP
  class Socket
    class TCPSocket
      extend Forwardable

      def initialize(scheduler, host, port)
        if block_given?
          raise ArgumentError, "block form is not supported"
        end

        # TODO: IPv6, non-blocking DNS lookup
        @state = :connecting

        @write_buffer = ""

        @scheduler = scheduler
        @socket = ::Socket.new(::Socket::AF_INET, ::Socket::SOCK_STREAM, 0)
        @monitor = @scheduler.register(@socket)

        operate do
          begin
            puts "Connecting."
            @socket.connect_nonblock ::Socket.sockaddr_in(port, host)
          rescue Errno::EISCONN
            puts "Connected."
          end
        end
      end

      # HTTP::Client
      def_delegators :@socket, :closed?, :close

      # HTTP::Client
      def readpartial(maxlength, outbuf = nil)
        operate do
          @socket.read_nonblock(maxlength, *outbuf)
        end
      end

      def close
        # TODO: Is this really guaranteed to be called?
        @scheduler.deregister(self)
        @socket.close
      end

      # HTTP::Request::Writer
      def <<(data)
        operate do
          @write_buffer.replace(data)
          write_remaining = data.bytesize

          while write_remaining > 0
            written = @socket.write_nonblock(@write_buffer)
            @write_buffer.slice!(0, written)
            write_remaining -= written
          end
        end
      end

      def to_io
        @socket
      end

      private

      def operate
        begin
          yield
        rescue IO::WaitWritable, IO::WaitReadable => ex
          Fiber.yield
          retry
        end
      end
    end

    def initialize(scheduler)
      @scheduler = scheduler
    end

    def open(remote_host, remote_port)
      TCPSocket.new(@scheduler, remote_host, remote_port)
    end
  end
end
