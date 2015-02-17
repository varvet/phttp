#!/usr/bin/env ruby

$:.push File.expand_path('../../lib', __FILE__)
require 'nio'
require 'socket'

class EchoServer
  def initialize(host, port)
    @selector = NIO::Selector.new

    puts "Listening on #{host}:#{port}"
    @server = TCPServer.new(host, port)

    monitor = @selector.register(@server, :r)
    monitor.value = proc { accept }
  end

  def run
    while true
      @selector.select { |monitor| monitor.value.call(monitor) }
    end
  end

  def accept
    socket = @server.accept
    print_status(socket, "connected")

    monitor = @selector.register(socket, :r)
    monitor.value = proc { read(socket) }
  end

  def read(socket)
    state = :reading
    data = ""

    loop do
      begin
        case state
        when :reading
          puts "Reading."
          data << socket.read_nonblock(4096)
          print_status(socket, "data: #{data.bytesize}")

          if data[-1] == "\x00"
            data.upcase!
            state = :writing
          end
        when :writing
          if data.bytesize > 0
            puts "Writing: #{data.bytesize}"
            written = socket.write_nonblock(data)
            data.slice!(0, written)
          else
            print_status(socket, "closed")
            return
          end
        end
      rescue IO::WaitReadable
      rescue IO::WaitWritable
      end
    end
  rescue EOFError
    print_status(socket, "disconnected")
  ensure
    @selector.deregister(socket)
    socket.close
  end

  def print_status(socket, message)
    _, port, host = socket.peeraddr
    puts "#{host}:#{port} #{message}"
  end
end

if $0 == __FILE__
  EchoServer.new("127.0.0.1", 1234).run
end
