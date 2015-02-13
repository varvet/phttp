require "http.rb"
require "nio"

module PHTTP
  class Client
    def initialize(options)
      @client = HTTP::Client.new(options.merge({
        socket_class: ::TCPSocket,
      }))
    end

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
      response = yield @client.request(verb, uri, options)
    end
  end
end

def PHTTP(options = {})
  client = PHTTP::Client.new(options)
  yield client
end
