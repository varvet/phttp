require "phttp"
require "pry"

Typhoeus::Config.block_connection = true

describe PHTTP do
  before do
    Typhoeus::Expectation.clear
  end

  def stub_request(url, response_body)
    response = Typhoeus::Response.new(body: response_body)
    stub = Typhoeus.stub(url)
    stub.and_return(response)
    stub.and_return do |request|
      raise "can't be called more than once"
    end
    stub
  end

  it "returns the value from the promise returned from the block" do
    stub_request("http://example.com/", "something cool")

    result = PHTTP::Request.new("http://example.com/").run
    result.body.should eq "something cool"
  end

  it "can chain a promise" do
    stub_request("http://example.com/", "something cool")

    request = PHTTP::Request.new("http://example.com/").then do |response|
      response.body.upcase
    end

    request.run.should eq "SOMETHING COOL"
  end

  it "can chain multiple promises" do
    stub_request("http://example.com/", "cool")
    stub_request("http://example.com/cool", "cow")
    stub_request("http://example.com/cow", "something else")

    request = PHTTP::Request.new("http://example.com/").then do |response|
      PHTTP::Request.new("http://example.com/#{response.body}").then do |response|
        PHTTP::Request.new("http://example.com/#{response.body}").then do |response|
          response.body.upcase
        end
      end
    end

    request.run.should eq "SOMETHING ELSE"
  end

  it "can run fork requests" do
    stub_request("http://example.com/", "bowl cool")
    stub_request("http://example.com/cool", "cool")
    stub_request("http://example.com/bowl", "bowl")

    request = PHTTP::Request.new("http://example.com/")

    requestA = request.then do |response|
      bowl, cool = response.body.split(" ")
      PHTTP::Request.new("http://example.com/#{bowl}").then do |response|
        response.body.upcase
      end
    end

    requestB = request.then do |response|
      bowl, cool = response.body.split(" ")
      PHTTP::Request.new("http://example.com/#{cool}").then do |response|
        response.body.upcase
      end
    end

    PHTTP.all(requestA, requestB).run.should eq ["BOWL", "COOL"]
  end

  it "can do parallell promises" do
    stub_request("http://example.com/cool", "COOL")
    stub_request("http://example.com/cow", "cow")

    a = PHTTP::Request.new("http://example.com/cool").then do |response|
      response.body.downcase
    end

    b = PHTTP::Request.new("http://example.com/cow").then do |response|
      response.body.upcase
    end

    request = PHTTP.all(a, b).then do |x, y|
      x + " " + y + "!"
    end

    request.run.should eq "cool COW!"
  end

  it "can do parallell nested promises" do
    stub_request("http://example.com/cool", "bowl")
    stub_request("http://example.com/bowl/a", "monkey")
    stub_request("http://example.com/bowl/b", "llama")
    stub_request("http://example.com/cow", "cow")

    a = PHTTP::Request.new("http://example.com/cool").then do |response|
      x = PHTTP::Request.new("http://example.com/#{response.body}/a").then { |res| res.body }
      y = PHTTP::Request.new("http://example.com/#{response.body}/b").then { |res| res.body }
      PHTTP.all(x, y)
    end

    b = PHTTP::Request.new("http://example.com/cow").then { |res| res.body }

    request = PHTTP.all(a, b).then do |(xa, xb), y|
      [xa, xb, y].join(", ")
    end

    request.run.should eq "monkey, llama, cow"
  end

  it "can compose promises which are already fulfilled" do
    stub_request("http://example.com/x", "monkey")

    a = PHTTP::Request.new("http://example.com/x")
    a.run
    a.value.should be_an_instance_of(Typhoeus::Response)

    promise = a.then { |res| res.body.upcase }
    promise.value.should eq "MONKEY"
  end

  it "has promises for primitive values" do
    seven = PHTTP.of(5).then do |response|
      response + 2
    end

    seven.run.should eq 7
  end

  it "can compose primitive and non primitive promises" do
    stub_request("http://example.com/x", "monkey")

    result = PHTTP.of("x").then do |x|
      a = PHTTP::Request.new("http://example.com/#{x}").then { |res| res.body }
      PHTTP.all(a, PHTTP.of("llama"))
    end.then do |x, y|
      x + y
    end

    result.run.should eq "monkeyllama"
  end

  it "resolves a empty all to an empty array" do
    stub_request("http://example.com/0", "monkey")

    result = PHTTP.all.then { |x| PHTTP::Request.new("http://example.com/#{x.length}") }.then { |res| res.body }

    result.run.should eq "monkey"
  end
end
