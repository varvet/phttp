require "typhoeus"
require "forwardable"
require "delegate"
require "json"

module PHTTP
  module Completeable
    def complete(result)
      if result.is_a?(Completeable)
        result.on_complete { |result| complete(result) }
      else
        @on_complete.call(result) if @on_complete
      end
    end

    def on_complete(&block)
      @on_complete = block
    end
  end

  class MultipleRequests
    include Completeable

    def initialize(requests, &block)
      @results = Array.new(requests.length)

      total = @results.length
      completed = 0

      requests.each_with_index do |request, index|
        request.on_complete do |response|
          @results[index] = response
          completed += 1
          complete(response) if completed == total
        end
      end

      on_complete(&block)
    end

    def response
      @results
    end
  end

  class Request < SimpleDelegator
    include Completeable

    def initialize(*args)
      request = Typhoeus::Request.new(*args)
      request.on_complete do |response|
        response = Response.new(response)
        result = yield response
        complete(result)
      end if block_given?

      super request
    end
  end

  class Response < SimpleDelegator
    def response_json
      JSON.parse(response_body)
    end

    alias_method :json, :response_json
  end

  class Foundation
    attr_reader :hydra

    def initialize(hydra = Typhoeus::Hydra.new)
      @hydra = hydra
    end

    def run
      request = yield self
      hydra.run
      request.response
    end

    def request(url, options = {}, &block)
      request = Request.new(url, options, &block)
      hydra.queue request
      request
    end

    def all(*requests, &block)
      MultipleRequests.new(requests, &block)
    end
  end

  def self.parallel(&block)
    root = Foundation.new
    root.run(&block)
  end
end
