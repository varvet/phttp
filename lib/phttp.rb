require "http.rb"
require "nio"

module PHTTP
  class TCPSocket
    extend Forwardable

    def self.open(*args)
      if block_given?
        raise ArgumentError, "block form is not supported"
      end

      new(*args)
    end

    def initialize(*args)
      @io = ::TCPSocket.open(*args)
    end

    # HTTP::Client
    def_delegators :@io, :readpartial, :closed?, :close

    # HTTP::Request::Writer
    def_delegators :@io, :<<
  end

  class Client
    def initialize(options)
      @options = options
    end

    attr_reader :options

    def get(uri)
      request(:get, uri) do |response|
        if block_given?
          yield response
        else
          response
        end
      end
    end

    def request(verb, uri, options = {})
      response = yield client.request(verb, uri, options)
    end

    private

    def client
      HTTP::Client.new(options.merge({
        socket_class: PHTTP::TCPSocket,
      }))
    end
  end
end

def PHTTP(options = {})
  client = PHTTP::Client.new(options)
  yield client
end
