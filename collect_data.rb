#!/usr/bin/env ruby
#
# Collect coverage report data via CircleCI REST API
#
require 'httpclient'
require 'json'
require 'dotenv'
Dotenv.load

latest_build_num = ARGV[0]
oldest_build_num = ARGV[1]

if latest_build_num.nil? || oldest_build_num.nil?
  puts <<USAGE
$ ruby ./collect_data.rb [LATEST_BUILD_NUM] [OLDEST_BUILD_NUM]

Example:
  ruby ./collect_data.rb 1890 1000

USAGE
  exit!
end

user    = ENV["CIRCLECI_USER"]
project = ENV["CIRCLECI_PROJECT"]
token   = ENV["CIRCLECI_TOKEN"]
url_base = "https://circleci.com/api/v1/project/#{user}/#{project}/%d?circle-token=#{token}"

http = HTTPClient.new
http.transparent_gzip_decompression = true

# [build_num, type, percentage, covered, total]
statements = []
branches = []
functions = []
lines = []

def decode_json(res)
  JSON.parse(res.body, symbolize_names: true)
end

latest_build_num.to_i.downto(oldest_build_num.to_i) do |build_num|
  $stderr.puts build_num

  url = url_base % build_num
  res = http.get(url)
  json = decode_json(res)
  next if json[:branch] != "master"

  step = json[:steps].detect {|step|
    step[:name] == "bundle exec teaspoon --coverage navi"
  }
  next if step.nil?

  output_url = step[:actions][0][:output_url]
  res = http.get(output_url)
  json = decode_json(res)
  message = json[0][:message]
  coverages = message.split("=============================== Coverage summary ===============================")[-1].gsub(/[\r\n]/, "").gsub(/\=+/, "")
  statement, branch, function, line = coverages.split(")")

  pattern = /(\w+)\s+:\s([\d\.]+)%\s\(\s(\d+)\/(\d+)/

  statements << statement.match(pattern).to_a[1..-1].unshift(build_num)
  branches << branch.match(pattern).to_a[1..-1].unshift(build_num)
  functions << function.match(pattern).to_a[1..-1].unshift(build_num)
  lines << line.match(pattern).to_a[1..-1].unshift(build_num)
end

f = open('tmp/cov.csv', 'w')
f.puts statements.map{ |item| item.join(",") }.reverse
f.puts branches.map{ |item| item.join(",") }.reverse
f.puts functions.map{ |item| item.join(",") }.reverse
f.puts lines.map{ |item| item.join(",") }.reverse

def run command
  puts command
  system command
end

run "grep Statements tmp/cov.csv > tmp/cov-s.csv"
run "grep Branches tmp/cov.csv > tmp/cov-b.csv"
run "grep Functions tmp/cov.csv > tmp/cov-f.csv"
run "grep Lines tmp/cov.csv > tmp/cov-l.csv"

# def output(items)
#   puts items.map{ |item| item.join(",") }.reverse
# end

# output(statements)
# output(branches)
# output(functions)
# output(lines)
