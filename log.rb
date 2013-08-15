#!/usr/bin/env ruby

require 'date'
require 'fileutils'
require 'trollop'
require 'yaml'

$DEFAULT_FILE = File.expand_path("~/.log/data")

$OPTIONALS = [[:author, "Author", :type => String],
              [:place, "Place", :type => String],
              [:tags, "Tags (comma-separated)", :type => String]]

class Log
  def initialize(filename)
    @filename = filename
    @entries = if File.exists? @filename
                 YAML.load_file( @filename ).map { |h| LogEntry[h] }
               else
                 FileUtils.mkdir_p(File.dirname($DEFAULT_FILE))
                 Array.new
               end
  end

  def add_entry(entry)
    @entries.push(entry)
  end

  def list
    @entries.each do |entry|
      puts entry.to_s
    end
  end

  def clean_hashed_entries
    @entries.map { |e| e.clean_hash }
  end

  def save
    File.open( @filename, 'w' ) do |out|
      YAML.dump( clean_hashed_entries, out )
    end
  end
end

class LogEntry < Hash
  def set_date
    self['date'] = DateTime.now.strftime
  end

  def clean_hash
    Hash[self].reject { |k, v| v.nil? }
  end

  def add_cl_optionals(*args)
    update(*args)
    set_date
    self['tags'] = self['tags'].split(',') if !self['tags'].nil?
  end

  def to_s
    time = DateTime.strptime(self['date']).strftime('%F %H%M')
    "#{time} | #{self['text']}"
  end
end

def options
  opts = Trollop::options do
    opt :data_file, "Log file", :default => $DEFAULT_FILE
    opt :list, "List entries"
    $OPTIONALS.map do |l|
      opt(*l)
    end
  end
  #Trollop::die :data_file, "must exist" unless File.exist?(opts[:data_file]) if opts[:data_file]
  opts
end

def main
  opts = options
  l = Log.new(opts.data_file)
  text = ARGV.join(' ')
  if opts.list
    l.list
  elsif !text.empty?
    entry = LogEntry['text' => text]
    entry.add_cl_optionals(LogEntry[$OPTIONALS.map do |l|
                                      optional = l.first.to_s
                                      [optional, opts.send(optional)]
                                    end])
    l.add_entry(entry)
    l.save
  else
    l.list
    #Trollop.die('No action or message')
  end
end

main
