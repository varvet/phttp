require "typhoeus"
require "forwardable"
require "delegate"
require "json"

module PHTTP
  module Promise
    def initialize(&on_fulfill)
      @promises = []
      @on_fulfill = on_fulfill
    end

    attr_reader :value

    def fulfill(value)
      return if defined?(@value)

      value = @on_fulfill.call(value) if @on_fulfill

      finish = lambda do |value|
        @value = value

        @promises.each do |promise|
          promise.fulfill(@value)
        end
      end

      if value.is_a?(Promise)
        value.then(&finish)
      else
        finish[value]
      end

      nil
    end

    def queue(hydra)
      original = @on_fulfill
      @on_fulfill = lambda do |value|
        value = original[value] if original
        value.queue(hydra) if value.is_a?(Promise)
        value
      end
    end

    def then(&block)
      promise = Filter.new(self, &block)
      @promises << promise
      promise.fulfill(@value) if defined?(@value)
      promise
    end

    def run(*args)
      hydra = Typhoeus::Hydra.new(*args)
      queue(hydra)
      hydra.run
      value
    end
  end

  class Filter
    include Promise

    def initialize(parent, &on_fulfill)
      @parent = parent
      super(&on_fulfill)
    end

    def queue(hydra)
      super
      @parent.queue(hydra)
    end
  end

  class CompoundRequest
    include Promise

    def initialize(requests)
      super(&nil)

      @requests = requests

      results = Array.new(@requests.length)
      completed = 0

      @requests.each_with_index do |request, index|
        request.then do |response|
          results[index] = response
          completed += 1

          fulfill(results) if completed == results.length
        end
      end
    end

    def queue(hydra)
      super
      @requests.each do |request|
        request.queue(hydra)
      end
    end
  end

  class Request
    include Promise

    def initialize(*args)
      super(&nil)

      @request = Typhoeus::Request.new(*args)

      @request.on_complete do |response|
        fulfill(response)
      end
    end

    attr_reader :request

    def queue(hydra)
      super
      hydra.queue(request) unless hydra.queued_requests.include?(request)
    end
  end

  class << self
    def all(*requests)
      CompoundRequest.new(requests.flatten)
    end
  end
end
