require "typhoeus"
require "forwardable"
require "delegate"
require "json"

module PHTTP
  class Promise
    def initialize(parent, &on_fulfill)
      @parent = parent
      @promises = []
      @on_fulfill = on_fulfill
    end

    attr_reader :value

    def fulfill(value)
      return if defined?(@value)

      value = @on_fulfill.call(value) if @on_fulfill

      if value.is_a?(Promise)
        value.then do |value|
          @value = value

          @promises.each do |promise|
            promise.fulfill(@value)
          end
        end
      else
        @value = value

        @promises.each do |promise|
          promise.fulfill(@value)
        end
      end

      nil
    end

    def then(&block)
      promise = Promise.new(self, &block)
      @promises << promise
      promise.fulfill(@value) if defined?(@value)
      promise
    end

    def run
      if @on_fulfill
        @on_fulfill.call(@parent.run)
      else
        @parent.run
      end
    end
  end

  class HTTPPromise < Promise
    def initialize(reactor, request)
      super(nil, &nil)
      @reactor = reactor
      @request = request
      @queued = false
    end

    def then(&block)
      unless @queued
        @queued = true
        @request.on_complete { |response| fulfill(response) }
        @reactor.queue(@request)
      end
      super(&block)
    end

    def run
      @_run ||= @request.run
    end
  end

  class Reactor
    attr_reader :hydra

    def initialize(hydra = Typhoeus::Hydra.new)
      @hydra = hydra
      @value = yield self

      if @value.is_a?(Promise)
        @value.then
      end
    end

    def run
      hydra.run
    end

    def value
      if @value.is_a?(Promise)
        @value.value
      else
        @value
      end
    end

    def queue(request)
      hydra.queue(request)
    end

    def request(url, options = {})
      HTTPPromise.new(self, Typhoeus::Request.new(url, options))
    end

    def all(*promises)
      promise = Promise.new(hydra)
      results = Array.new(promises.length)
      completed = 0

      promises.each_with_index do |request, index|
        request.then do |response|
          results[index] = response
          completed += 1

          if completed == results.length
            promise.fulfill(results)
          end
        end
      end

      promise
    end
  end

  def self.parallel(&block)
    reactor = Reactor.new(&block)
    reactor.run
    reactor.value
  end
end
