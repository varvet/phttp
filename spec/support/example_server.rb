require "rack"
require "thread"
require "logger"

module HTTPMocks
  class MockServer
    def initialize
      q = Queue.new
      @thread = Thread.new do
        options = { Logger: Logger.new(File::NULL), AccessLog: File::NULL }
        Rack::Handler::WEBrick.run(self, options) { |s| q << s }
      end
      @server = q.pop
    end

    def call(env)
      [204, {}, [""]]
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
