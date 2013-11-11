require "phttp"
require "pry"

Typhoeus::Config.block_connection = true

describe PHTTP do
  it "something" do
    mock_response = Typhoeus::Response.new(body: "something cool")
    Typhoeus.stub("http://example.com/").and_return(mock_response)

    result = PHTTP.parallel do |http|
      http.request("http://example.com/").then do |response|
        response.body.upcase
      end
    end

    result.should eq "SOMETHING COOL"
  end

  it "something else" do
    mock_response = Typhoeus::Response.new(body: "something cool")
    Typhoeus.stub("http://example.com/").and_return(mock_response)

    result = PHTTP.parallel do |http|
      http.request("http://example.com/")
    end

    result.should eq mock_response
  end
end
