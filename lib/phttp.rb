require "fiber"

require "http.rb"
require "nio"

require "phttp/tcp_socket"
require "phttp/tree"
require "phttp/version"

module PHTTP
  class Error < StandardError; end

  class Scheduler
    def initialize
      @selector = NIO::Selector.new
    end

    # @api private
    def register(socket, interest = :rw)
      @selector.register(socket, interest)
    end

    # @api private
    def deregister(socket)
      @selector.deregister(socket)
    end

    def run
      fiber = Fiber.new do
        yield
      end

      while fiber.alive?
        fiber.resume

        puts "Selecting."
        if @selector.empty?
          break
        else
          @selector.select
        end
      end

      puts "Fiber done."
    end
  end
end

def PHTTP(options = {}, &block)
  scheduler = PHTTP::Scheduler.new
  tree = PHTTP::Tree.new(options, &block)
  scheduler.run(tree)
end
