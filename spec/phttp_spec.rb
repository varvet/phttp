RSpec.describe PHTTP do
  it "can run a single simple request" do
    response = mock_server do |server|
      expect(server).to receive_request(:get, "/").and_return("something cool")

      PHTTP { |http| http.get(server["/"]).to_s }
    end

    expect(response).to eq "something cool"
  end

  it "can run parallel requests" do
    response = mock_server do |server|
      expect(server).to receive_request(:get, "/").and_return(
        "something cool",
        "something else",
      )

      PHTTP do |http|
        responseA = http.get(server["/"])
        responseB = http.get(server["/"])

        [responseA, "and", responseB].join(" ")
      end
    end

    expect(response).to eq "something cool and something else"
  end

  it "can run compound requests" do
    response = mock_server do |server|
      expect(server).to receive_request(:get, "/").and_return(server["/next"])
      expect(server).to receive_request(:get, "/next").and_return("something cool")

      PHTTP do |http|
        http.get(server["/"]) do |res|
          http.get(res).to_s
        end
      end
    end

    expect(response).to eq "something cool"
  end

  it "can run multiple parallel requests" do
    response = mock_server do |server|
      expect(server).to receive_request(:get, "/a").and_return(server["/1"])
      expect(server).to receive_request(:get, "/b").and_return(server["/2"])
      expect(server).to receive_request(:get, "/1").and_return("1")
      expect(server).to receive_request(:get, "/2").and_return("2")

      PHTTP do |http|
        one = http.get(server["/a"]) do |res|
          http.get(res)
        end

        two = http.get(server["/b"]) do |res|
          http.get(res)
        end

        [one.to_s, two.to_s]
      end
    end

    expect(response).to eq ["1", "2"]
  end
end
