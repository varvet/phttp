RSpec.describe PHTTP do
  it "can run a single simple request" do
    response = mock_server do |server|
      expect(server).to receive_request(:get, "/").and_return([200, {}, ["something cool"]])

      PHTTP { |http| http.get(server["/"]).to_s }
    end

    expect(response).to eq "something cool"
  end

  it "can run parallel requests" do
    response = mock_server do |server|
      expect(server).to receive_request(:get, "/").and_return(
        [200, {}, ["something cool"]],
        [200, {}, ["something else"]],
      )

      PHTTP do |http|
        responseA = http.get(server["/"]).to_s
        responseB = http.get(server["/"]).to_s

        [responseA, "and", responseB].join(" ")
      end
    end

    expect(response).to eq "something cool and something else"
  end

  it "can run compound requests" do
    response = mock_server do |server|
      expect(server).to receive_request(:get, "/").and_return([200, {}, [server["/next"]]])
      expect(server).to receive_request(:get, "/next").and_return([200, {}, ["something cool"]])

      PHTTP do |http|
        http.get(server["/"]) { |res| http.get(res).to_s }
      end
    end

    expect(response).to eq "something cool"
  end

  it "can run multiple parallel requests" do
    response = mock_server do |server|
      expect(server).to receive_request(:get, "/a").and_return([200, {}, [server["/1"]]])
      expect(server).to receive_request(:get, "/b").and_return([200, {}, [server["/2"]]])
      expect(server).to receive_request(:get, "/1").and_return([200, {}, ["1"]])
      expect(server).to receive_request(:get, "/2").and_return([200, {}, ["2"]])

      PHTTP do |http|
        one = http.get(server["/a"]) { |res| http.get(res).to_s }
        two = http.get(server["/b"]) { |res| http.get(res).to_s }
        [one, two]
      end
    end

    expect(response).to eq ["1", "2"]
  end
end
