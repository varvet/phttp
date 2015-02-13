require "rack"
require "thread"
require "logger"

module HTTPMocks
  class MockServer
    def initialize
      q = Queue.new
      @thread = Thread.new(self) do |mock|
        app = lambda do |env|
          response = mock.call(env)
          response = [200, {}, [response]] if response.is_a?(String)
          response
        end

        options = { Logger: Logger.new(File::NULL), AccessLog: File::NULL }
        Rack::Handler::WEBrick.run(app, options) { |s| q << s }
      end
      @server = q.pop
    end

    def call(env)
      ""
    end

    def [](path)
      "http://#{@server.config[:BindAddr]}:#{@server.config[:Port]}#{path}"
    end

    def shutdown
      @server.shutdown
      @thread.join
    end
  end

  def receive_request(method, url, &block)
    receive(:call).with(hash_including("PATH_INFO" => url), &block)
  end

  def mock_server
    server = MockServer.new
    value = yield server
    RSpec::Mocks.verify
    value
  ensure
    server.shutdown
  end
end

RSpec.configure do |config|
  config.include HTTPMocks
end
