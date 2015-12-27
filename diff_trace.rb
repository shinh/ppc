#!/usr/bin/env ruby

fn = ARGV[0]
if !fn
  raise
end

b = File.basename(fn)
a = %W(exe/#{b}.trace tb/cpu_trace.#{b}.trace)
system("diff -U 40 #{a * ' '}")
