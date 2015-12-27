#!/usr/bin/ruby

d = File.open(ARGV[0], 'r:binary', &:read)
a = ''
d.each_byte{|b|
  a += '%02x' % b
  if a.size == 8
    puts a.split("") * "_"
    a = ''
  end
}

if a.size > 0
  while a.size != 8
    a += '00'
  end
  puts a.split("") * "_"
end

__END__

d = `objdump -s -j .init -j .text #{ARGV[0]}`
d.sub!(/.*?\.(init|text):\n/ms, '')
d.gsub!(/  .*/, '')
d.scan(/\s(\h{8})/) do
  puts $1.split("") * "_"
end
