#!/usr/bin/env ruby
require 'optparse'
require_relative "../lib/tachiban/policy_generator/policy_generator.rb"


options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "\nHanami authorization policy generator
Usage: tachiban -n myapp -p user
Flags:
\n"

  opts.on("-n", "--app_name APP", "Specify the application name for the policy") do |app_name|
    options[:app_name] = app_name
  end

  opts.on("-p", "--policy POLICY", "Specify the policy name") do |policy|
    options[:policy] = policy
  end

  opts.on("-h", "--help", "Displays help") do
    puts opts
    exit
  end

end


begin
  optparse.parse!
  puts "Add flag -h or --help to see usage instructions." if options.empty?
  mandatory = [:app_name, :policy]
  missing = mandatory.select{ |arg| options[arg].nil? }
  unless missing.empty?
    raise OptionParser::MissingArgument.new(missing.join(', '))
  end

rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit
end

puts "Performing task with options: #{options.inspect}"
generate_policy("#{options[:app_name]}", "#{options[:policy]}") if options[:policy]
