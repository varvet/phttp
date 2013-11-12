require "phttp"
require "pry"

Typhoeus::Config.block_connection = true

describe PHTTP do
  before do
    Typhoeus::Expectation.clear
  end

  it "returns the value from the promise returned from the block" do
    mock_response = Typhoeus::Response.new(body: "something cool")
    Typhoeus.stub("http://example.com/").and_return(mock_response)

    result = PHTTP::Request.new("http://example.com/").run
    result.should eq mock_response
  end

  it "can chain a promise" do
    mock_response = Typhoeus::Response.new(body: "something cool")
    Typhoeus.stub("http://example.com/").and_return(mock_response)

    request = PHTTP::Request.new("http://example.com/").then do |response|
      response.body.upcase
    end

    request.run.should eq "SOMETHING COOL"
  end

  it "can chain multiple promises" do
    mock_response = Typhoeus::Response.new(body: "cool")
    Typhoeus.stub("http://example.com/").and_return(mock_response)

    mock_response = Typhoeus::Response.new(body: "cow")
    Typhoeus.stub("http://example.com/cool").and_return(mock_response)

    mock_response = Typhoeus::Response.new(body: "something else")
    Typhoeus.stub("http://example.com/cow").and_return(mock_response)

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
    Typhoeus.stub("http://example.com/").and_return(Typhoeus::Response.new(body: "bowl cool"))
    Typhoeus.stub("http://example.com/cool").and_return(Typhoeus::Response.new(body: "cool"))
    Typhoeus.stub("http://example.com/bowl").and_return(Typhoeus::Response.new(body: "bowl"))

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
    mock_response = Typhoeus::Response.new(body: "COOL")
    Typhoeus.stub("http://example.com/cool").and_return(mock_response)

    mock_response = Typhoeus::Response.new(body: "cow")
    Typhoeus.stub("http://example.com/cow").and_return(mock_response)

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
    Typhoeus.stub("http://example.com/cool").and_return(Typhoeus::Response.new(body: "bowl"))
    Typhoeus.stub("http://example.com/bowl/a").and_return(Typhoeus::Response.new(body: "monkey"))
    Typhoeus.stub("http://example.com/bowl/b").and_return(Typhoeus::Response.new(body: "llama"))
    Typhoeus.stub("http://example.com/cow").and_return(Typhoeus::Response.new(body: "cow"))

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
    Typhoeus.stub("http://example.com/x").and_return(Typhoeus::Response.new(body: "monkey"))

    a = PHTTP::Request.new("http://example.com/x")
    a.run
    a.value.should be_an_instance_of(Typhoeus::Response)

    promise = a.then { |res| res.body.upcase }
    Typhoeus.stub("http://example.com/x").and_return(Typhoeus::Response.new(body: "something else"))
    promise.run

    promise.value.should eq "MONKEY"
  end
end
