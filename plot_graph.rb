#!/usr/bin/env ruby
#
# Create graph to plot data by gnuplot
#
require 'erb'

unless File.exist?('tmp/cov.csv')
  puts <<USAGE
tmp/cov.csv does not exist.
Please run ./collect_data.rb first.

USAGE
  exit!
end

def run command
  puts command
  system command
end

run "rm tmp/*.plt"
run "rm tmp/*.png"

tmpl1 = <<TMPL
set datafile separator ","
set terminal png

set output "<%= h[:name] %>.png"
set title "<%= h[:title] %>"
set xlabel "<%= h[:xlabel] %>"
set ylabel "<%= h[:ylabel] %>"
set label 1 "percentage"

plot "<%= h[:filename] %>" using 1:3 title "coverage" with lines
TMPL

tmpl2 = <<TMPL
set datafile separator ","
set terminal png

set output "<%= h[:name] %>.png"
set title "<%= h[:title] %>"
set xlabel "<%= h[:xlabel] %>"
set ylabel "<%= h[:ylabel] %>"
set label 1 "covered"
set label 2 "total"

plot "<%= h[:filename] %>" using 1:4 title "covered" with lines, "<%= h[:filename] %>" using 1:5 title "total" with lines
TMPL

blk = proc { |tmpl, h|
  plot = ERB.new(tmpl).result binding
  open("tmp/#{h[:name]}.plt", "w") {|f| f.write plot }
  run("cd tmp && gnuplot #{h[:name]}.plt")
  # system("open #{h[:name]}.png")
}

[
  {
    name: "statements-percentage",
    title: "Statements Coverages (Percentage)",
    xlabel: "Build Number",
    ylabel: "Percentage",
    filename: "cov-s.csv"
  },
  {
    name:
    "branches-percentage",
    title: "Branches Coverages (Percentage)",
    xlabel: "Build Number",
    ylabel: "Percentage",
    filename: "cov-b.csv"
  },
  {
    name: "functions-percentage",
    title: "Functions Coverages (Percentage)",
    xlabel: "Build Number",
    ylabel: "Percentage",
    filename: "cov-f.csv"
  },
  {
    name: "lines-percentage",
    title: "Lines Coverages (Percentage)",
    xlabel: "Build Number",
    ylabel: "Percentage",
    filename: "cov-l.csv"
  },
].each do |h|
  blk.call(tmpl1, h)
end

[
  {
    name: "statements-lines",
    title: "Statements Coverages",
    xlabel: "Build Number",
    ylabel: "Statements",
    filename: "cov-s.csv"
  },
  {
    name: "branches-lines",
    title: "Branches Coverages",
    xlabel: "Build Number",
    ylabel: "Branches",
    filename: "cov-b.csv"
  },
  {
    name: "functions-lines",
    title: "Functions Coverages",
    xlabel: "Build Number",
    ylabel: "Functions",
    filename: "cov-f.csv"
  },
  {
    name: "lines-lines",
    title: "Lines Coverages",
    xlabel: "Build Number",
    ylabel: "Lines",
    filename: "cov-l.csv"
  },
].each do |h|
  blk.call(tmpl2, h)
end
