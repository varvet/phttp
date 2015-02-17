$LOAD_PATH.unshift "lib"

require "pry"
require "phttp"

puts "Creating scheduler"
scheduler = PHTTP::Scheduler.new
socket = PHTTP::Socket.new(scheduler)

puts "Running"
scheduler.run do
  puts "Creating socket."
  socket = socket.open("127.0.0.1", 1234)
  puts "< Hello, world!"
  socket << "Hello, world!\x00"

  begin
    while response = socket.readpartial(1024 * 100)
      puts "> #{response}"
    end
  rescue EOFError
  end

  puts "Done."
end
