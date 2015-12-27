#!/usr/bin/env ruby

o = ''
$<.read.scan(/OUT: (.)/ms){
  o += $1
}
print o
