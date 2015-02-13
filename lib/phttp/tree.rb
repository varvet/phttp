module PHTTP
  class Tree
    def initialize(options, &block)
      @options = options
      @block = block
    end

    attr_reader :options

    def call(*args)
      @block[self, *args]
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
      new_client = HTTP::Client.new(options.merge({
        socket_class: PHTTP::TCPSocket,
      }))

      response = yield new_client.request(verb, uri, options)
    end
  end
end
