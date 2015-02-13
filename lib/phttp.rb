require "http.rb"
require "nio"

require "phttp/tcp_socket"
require "phttp/tree"
require "phttp/version"

module PHTTP
  class Scheduler
    def initialize(tree)
      @tree = tree
    end

    def run
      @tree.call
    end
  end
end

def PHTTP(options = {}, &block)
  tree = PHTTP::Tree.new(options, &block)
  scheduler = PHTTP::Scheduler.new(tree)
  scheduler.run
end
