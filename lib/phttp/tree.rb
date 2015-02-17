module PHTTP
  class Tree
    def initialize(options, &block)
      @options = options
      @block = block
      @respones = []
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
      new_client = HTTP::Client.new(options.merge({
        socket_class: PHTTP::Socket.new(scheduler),
      }))

      response = new_client.request(verb, uri, options)
      @responses << response
      yield response
    end

    def run(scheduler)
      @scheduler = scheduler
      @block[self]
    ensure
      @responses.each(&:flush)
      @responses.clear
      @scheduler = nil
    end

    private

    def scheduler
      @scheduler or raise Error.new("No scheduler available.")
    end
  end
end
