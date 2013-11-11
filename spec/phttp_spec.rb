require "phttp"
require "pry"

Typhoeus::Config.block_connection = true

describe PHTTP do
  it "returns the value from the promise returned from the block" do
    mock_response = Typhoeus::Response.new(body: "something cool")
    Typhoeus.stub("http://example.com/").and_return(mock_response)

    result = PHTTP.parallel do |http|
      http.request("http://example.com/")
    end

    result.should eq mock_response
  end

  it "can chain a promise" do
    mock_response = Typhoeus::Response.new(body: "something cool")
    Typhoeus.stub("http://example.com/").and_return(mock_response)

    result = PHTTP.parallel do |http|
      http.request("http://example.com/").then do |response|
        response.body.upcase
      end
    end

    result.should eq "SOMETHING COOL"
  end

  it "can chain multiple promises" do
    mock_response = Typhoeus::Response.new(body: "cool")
    Typhoeus.stub("http://example.com/").and_return(mock_response)

    mock_response = Typhoeus::Response.new(body: "cow")
    Typhoeus.stub("http://example.com/cool").and_return(mock_response)

    mock_response = Typhoeus::Response.new(body: "something else")
    Typhoeus.stub("http://example.com/cow").and_return(mock_response)

    result = PHTTP.parallel do |http|
      http.request("http://example.com/").then do |response|
        http.request("http://example.com/#{response.body}").then do |response|
          http.request("http://example.com/#{response.body}").then do |response|
            response.body.upcase
          end
        end
      end
    end

    result.should eq "SOMETHING ELSE"
  end

  it "can do parallell promises" do
    mock_response = Typhoeus::Response.new(body: "COOL")
    Typhoeus.stub("http://example.com/cool").and_return(mock_response)

    mock_response = Typhoeus::Response.new(body: "cow")
    Typhoeus.stub("http://example.com/cow").and_return(mock_response)

    result = PHTTP.parallel do |http|
      a = http.request("http://example.com/cool").then do |response|
        response.body.downcase
      end

      b = http.request("http://example.com/cow").then do |response|
        response.body.upcase
      end

      http.all(a, b).then do |x, y|
        x + " " + y + "!"
      end
    end

    result.should eq "cool COW!"
  end

  it "can do parallell nested promises" do
    Typhoeus.stub("http://example.com/cool").and_return(Typhoeus::Response.new(body: "bowl"))
    Typhoeus.stub("http://example.com/bowl/a").and_return(Typhoeus::Response.new(body: "monkey"))
    Typhoeus.stub("http://example.com/bowl/b").and_return(Typhoeus::Response.new(body: "llama"))
    Typhoeus.stub("http://example.com/cow").and_return(Typhoeus::Response.new(body: "cow"))

    result = PHTTP.parallel do |http|
      a = http.request("http://example.com/cool").then do |response|
        x = http.request("http://example.com/#{response.body}/a").then { |res| res.body }
        y = http.request("http://example.com/#{response.body}/b").then { |res| res.body }
        http.all(x, y)
      end

      b = http.request("http://example.com/cow").then { |res| res.body }

      http.all(a, b).then do |(xa, xb), y|
        [xa, xb, y].join(", ")
      end
    end

    result.should eq "monkey, llama, cow"
  end
end
