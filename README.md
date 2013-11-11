# PHTTP

This gem makes it easier to compose multiple requests made through a Typhoeus
hydra by utilizing the idea of promises.

## Installation

```
$ gem install phttp
```

## Example

```ruby
require "phttp"

result = PHTTP.parallel do |http|
  cool = http.request("http://example.com/cool").then do |response|
    response.body.downcase
  end

  cow = http.request("http://example.com/cow").then do |response|
    response.body.upcase
  end

  http.all(cool, cow).then do |cool, cow|
    cool + " " + cow + "!"
  end
end

result.should eq "cool COW!"
```
