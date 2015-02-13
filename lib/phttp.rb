require "http.rb"
require "nio"

require "phttp/tcp_socket"
require "phttp/tree"
require "phttp/version"

module PHTTP
  def self.run(client)
    client.call
  end
end

def PHTTP(options = {}, &block)
  PHTTP.run(PHTTP::Tree.new(options, &block))
end
