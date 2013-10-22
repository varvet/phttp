require "bundler/setup"

module PHTTP
  require "typhoeus"
  require "forwardable"
  require "delegate"
  require "json"

  class Response < SimpleDelegator
    def response_json
      JSON.parse(response_body)
    end

    alias_method :json, :response_json
  end

  class Foundation
    extend Forwardable

    attr_reader :hydra

    def initialize(hydra = Typhoeus::Hydra.new, defaults)
      @hydra = hydra
      @defaults = defaults
      @queued = []
    end

    def queue(request)
      @queued << request
      hydra.queue(request)
    end

    def run
      yield self
      hydra.run
      @queued
    end

    def request(url, options = {}, &block)
      request = Typhoeus::Request.new(url, merge_defaults(options))
      request.on_complete(&create_callback(block)) if block_given?
      queue request
    end

    def merge_defaults(options = {})
      @defaults.merge(options) do |key, default, new|
        if default.respond_to?(:merge)
          default.merge(new)
        else
          new
        end
      end
    end

    def create_callback(callable)
      lambda { |response| callable.call Response.new(response) }
    end
  end

  def self.parallel(options = {}, &block)
    root = Foundation.new(options)
    root.run(&block)
  end
end

def api_url(path)
  url = URI.parse("https://gateway.int.ea.com/proxy/identity")
  url.path = path
  url.to_s
end

defaults = {
  method: :get,
  headers: { "X-Expand-Results" => "true" },
}

persona_uid = "400296307"

response = PHTTP.parallel(defaults) do |http|
  login_params = {
    grant_type: "client_credentials",
    client_id: "NFS14-Rivals-Web-Client",
    client_secret: "NFS14RivalsWebClientSecret"
  }

  http.request("https://accounts.int.ea.com/connect/token", method: :post, params: login_params) do |response|
    if response.success?
      puts "Yay: #{response.response_json}"
    else
      puts "Boo: #{response.code} => #{response.response_body}"
    end
  end
end
