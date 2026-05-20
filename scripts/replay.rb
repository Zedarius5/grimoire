#!/usr/bin/env ruby
# Serves a capture file as if it were a Lich session.
#
# Usage:
#   scripts/replay.rb <path-to-capture> [port] [--throttle ms]
#
#   --throttle <ms>   send one line every N milliseconds (default: send the
#                     whole file instantly, then keep the connection open).
#
# Unlike `nc -l`, this keeps the TCP connection alive after the file is sent
# so Grimoire stays in the "connected" state until you disconnect manually.

require 'socket'

path     = ARGV.shift or abort "usage: replay.rb <capture> [port] [--throttle ms]"
throttle = nil
port     = 8000

while (arg = ARGV.shift)
  if arg == '--throttle'
    throttle = ARGV.shift.to_i
  elsif arg =~ /^\d+$/
    port = arg.to_i
  end
end

server = TCPServer.new('127.0.0.1', port)
puts "replay: listening on 127.0.0.1:#{port}  (file: #{path})"

loop do
  client = server.accept
  puts "replay: client connected"
  begin
    if throttle
      File.foreach(path) do |line|
        client.write(line)
        sleep(throttle / 1000.0)
      end
    else
      client.write(File.read(path))
    end
    puts "replay: file sent; holding connection open (Ctrl-C to stop)"
    # Keep connection alive so the client stays "connected" until they
    # disconnect themselves.
    loop { sleep 60 }
  rescue Errno::EPIPE, IOError
    puts "replay: client disconnected"
  ensure
    client.close rescue nil
  end
end
