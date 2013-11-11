require "typhoeus"
require "forwardable"
require "delegate"
require "json"

module PHTTP
  # class Response < SimpleDelegator
  #   def response_json
  #     JSON.parse(response_body)
  #   end

  #   alias_method :json, :response_json
  # end

  # module Completeable
  #   def complete(result)
  #     if result.is_a?(Completeable)
  #       result.on_complete { |result| complete(result) }
  #     else
  #       @response = if @on_complete
  #         @on_complete.call(result)
  #       else
  #         result
  #       end
  #     end
  #   end

  #   def on_complete(&block)
  #     @on_complete = block
  #   end

  #   attr_reader :response
  # end

  # class MultipleRequests
  #   include Completeable

  #   def initialize(requests, &block)
  #     @results = Array.new(requests.length)

  #     total = @results.length
  #     completed = 0

  #     requests.each_with_index do |request, index|
  #       request.on_complete do |response|
  #         @results[index] = response
  #         completed += 1
  #         complete(response) if completed == total
  #       end
  #     end

  #     on_complete(&block)
  #   end

  #   def response
  #     @results
  #   end
  # end

  class Promise
    def initialize(&on_fulfill)
      @promises = []
      @on_fulfill = on_fulfill
    end

    attr_reader :value

    def fulfill(value)
      raise "can't fulfill promise twice" if defined?(@value)

      @value = if @on_fulfill
        @on_fulfill.call(value)
      else
        value
      end

      @promises.each do |promise|
        promise.fulfill(@value)
      end

      @value
    end

    def then(&block)
      promise = Promise.new(&block)
      @promises << promise
      promise
    end
  end

  class Foundation
    attr_reader :hydra

    def initialize(hydra = Typhoeus::Hydra.new)
      @hydra = hydra
    end

    def run
      promise = yield self
      hydra.run
      promise.value
    end

    def request(url, options = {})
      promise = Promise.new

      request = Typhoeus::Request.new(url, options)
      request.on_complete { |response| promise.fulfill(response) }
      hydra.queue request

      promise
    end

    # def all(*requests, &block)
    #   MultipleRequests.new(requests, &block)
    # end
  end

  def self.parallel(&block)
    root = Foundation.new
    root.run(&block)
  end
end
