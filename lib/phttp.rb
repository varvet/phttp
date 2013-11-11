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
      raise "can't fulfill promise twice" if defined?(@value)

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

    def all(*promises)
      promise = Promise.new
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
    root = Foundation.new
    root.run(&block)
  end
end
