RSpec.describe PHTTP do
  it "can run a single simple request" do
    stub_request(:get, "https://example.com")
      .to_return(body: "something cool")

    response = PHTTP { |http| http.get("https://example.com").to_s }

    expect(response).to eq "something cool"
  end

  it "can run parallel requests" do
    stub_request(:get, "https://example.com")
      .to_return(body: "something cool")
      .to_return(body: "something else")

    response = PHTTP do |http|
      responseA = http.get("https://example.com")
      responseB = http.get("https://example.com")
      [responseA.to_s, "and", responseB.to_s].join(" ")
    end

    expect(response).to eq "something cool and something else"
  end

  it "can run compound requests" do
    stub_request(:get, "https://example.com").to_return(body: "https://example.com/next")
    stub_request(:get, "https://example.com/next").to_return(body: "something cool")

    response = PHTTP do |http|
      http.get("https://example.com") do |response|
        http.get(response).to_s
      end
    end

    expect(response).to eq "something cool"
  end

  it "can run multiple parallel requests" do
    stub_request(:get, "https://example.com/a").to_return(body: "https://example.com/1")
    stub_request(:get, "https://example.com/b").to_return(body: "https://example.com/2")
    stub_request(:get, "https://example.com/1").to_return(body: "1")
    stub_request(:get, "https://example.com/2").to_return(body: "2")

    response = PHTTP do |http|
      one = http.get("https://example.com/a") { |response| http.get(response).to_s }
      two = http.get("https://example.com/b") { |response| http.get(response).to_s }
      [one, two]
    end

    expect(response).to eq ["1", "2"]
  end
end
