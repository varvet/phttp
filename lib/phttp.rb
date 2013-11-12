require "typhoeus"
require "forwardable"
require "delegate"
require "json"

module PHTTP
  class Promise
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

      if value.is_a?(Promise) or value.is_a?(Filter::Thenable)
        value.queue(@hydra)
        value.then(&finish)
      else
        finish[value]
      end

      nil
    end

    def queue(hydra)
      @hydra = hydra
    end

    def then(&block)
      promise = Promise.new(&block)
      @promises << promise
      promise.fulfill(@value) if defined?(@value)
      promise
    end
  end

  class Filter
    module Thenable
      def then(&block)
        Filter.new(self, @promise.then(&block))
      end

      def value
        @promise.value
      end
    end

    include Filter::Thenable

    def initialize(parent, promise)
      @parent = parent
      @promise = promise
    end

    def queue(hydra)
      @promise.queue(hydra)
      @parent.queue(hydra)
    end

    def run(*args)
      hydra = Typhoeus::Hydra.new(*args)
      @promise.queue(hydra)
      @parent.queue(hydra)
      hydra.run
      value
    end
  end

  class CompoundRequest
    include Filter::Thenable

    def initialize(requests)
      @promise = Promise.new
      @requests = requests

      results = Array.new(@requests.length)
      completed = 0

      @requests.each_with_index do |request, index|
        request.then do |response|
          results[index] = response
          completed += 1

          @promise.fulfill(results) if completed == results.length
        end
      end
    end

    def queue(hydra)
      @promise.queue(hydra)
      @requests.each do |request|
        request.queue(hydra)
      end
    end

    def run(*args)
      hydra = Typhoeus::Hydra.new(*args)
      @promise.queue(hydra)
      @requests.each { |request| request.queue(hydra) }
      hydra.run
      value
    end
  end

  class Request < SimpleDelegator
    include Filter::Thenable

    def initialize(*args, &block)
      @request = Typhoeus::Request.new(*args, &block)
      super(@request)

      @promise = Promise.new
      @request.on_complete do |response|
        @promise.fulfill(response)
      end
    end

    def run(*args)
      hydra = Typhoeus::Hydra.new(*args)
      @promise.queue(hydra)
      queue(hydra)
      hydra.run
      value
    end

    def queue(hydra)
      hydra.queue(@request)
    end
  end

  class << self
    def all(*requests)
      CompoundRequest.new(requests)
    end
  end
end
