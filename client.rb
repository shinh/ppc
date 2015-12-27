#!/usr/bin/env ruby
# -*- coding: binary -*-

require 'serialport'

def File.read(filename)
  File.open(filename, 'r:binary') do |f|
    f.read
  end
end

sp = SerialPort.new(Dir.glob('/dev/ttyUSB?')[0], 19200, 8, 1, 0)

wrbuf = ''
code = File.read(ARGV[0])
while code[-1] == "\0"
  code.chomp!("\0")
end
size = code.size
checksum = 0
code.each_byte{|b|
  checksum ^= b
}
STDERR.puts "code size=#{size} checksum=%x" % checksum

wrbuf << ((size >> 16) & 255)
wrbuf << ((size >> 8) & 255)
wrbuf << (size & 255)
wrbuf << code
wrbuf << checksum

while true
  rs, ws = IO::select([sp], [], [], 0.01)
  if rs && rs[0] == sp
    sp.getc
  else
    break
  end
end

inbuf = ''.b
start_time = nil
while true
  ws = []
  if !wrbuf.empty?
    ws = [sp]
  end

  rs, ws = IO::select([STDIN, sp], ws, [], 0.2)
  if rs && rs[0] == STDIN
    c = STDIN.getc
    wrbuf << c
  elsif rs && rs[0] == sp
    c = sp.getc
    STDOUT.write(c)
    STDOUT.flush
    if c == "\n"
      if inbuf =~ /\=== START ===/
        start_time = Time.new
      elsif inbuf =~ /\=== END ===/
        STDERR.puts Time.new - start_time
      end
      inbuf = ''
    else
      inbuf += c.b
    end
  end

  if ws && ws[0] == sp
    sp.write(wrbuf[0])
    wrbuf = wrbuf[1..-1]
    #if wrbuf.size % 1000 == 0
    #  STDERR.puts "#{wrbuf.size} left"
    #end
  end
end
