# frozen_string_literal: true

require 'faraday'
require 'inifile'

require_relative 'feedcheck_checks'

INI_FILE = 'planet.ini'           # ini file containing library of feeds
DEFAULT_AVATAR = 'default.png'    # name of image to use if avatar is not provided
AV_DIR = 'hackergotchi'           # folder containing local feed avatars
WORKER_COUNT = 3                  # number of concurrent workers
FEED_NAME_PADDING = 48            # number of characters before each ``=>`` in log output

faraday = Faraday.new(request: { open_timeout: 10 }) do |f|
  f.adapter :net_http
end

queue = Queue.new
ini_data = IniFile.load(INI_FILE).to_h
known_feed_names = ini_data.keys

ini_data.each do |feed_name, section|
  queue.push([feed_name, section]) if ARGV.empty? || ARGV.include?(feed_name)
end

error_messages = []
did_any_fail = false

missing_feed_names = ARGV - known_feed_names
missing_feed_names.each do |feed_name|
  puts "#{feed_name.ljust(FEED_NAME_PADDING)} =>  not found in #{INI_FILE}"
  error_messages << "#{feed_name}\nFeed not found in #{INI_FILE}"
  did_any_fail = true
end

puts "#{'::notice::Feed Errors Summary'.ljust(FEED_NAME_PADDING)} =>  (avatar) (link) (feed) (xml)"

avatars = [DEFAULT_AVATAR]
mutex = Mutex.new

workers = Array.new(WORKER_COUNT) do
  Thread.new do
    while (task = (queue.pop(true) rescue nil))
      feed_name, section = task
      next unless section.is_a?(Hash) && feed_name != 'global'

      result = check_source(feed_name, section, faraday, AV_DIR)
      puts "#{feed_name.ljust(FEED_NAME_PADDING)} =>  #{result.symbols}"

      mutex.synchronize do
        avatars << result.avatar
        error_messages << result.error_messages.unshift(feed_name) if result.failed
        did_any_fail ||= result.failed
      end
    end
  end
end
workers.each(&:join)

run_unused_check = ARGV.empty?
unused_files_message = run_unused_check ? check_unused_files(AV_DIR, avatars) : nil

if did_any_fail
  error_messages.each { |message| puts "::group::#{message.join("\n::error::#{message.first}: ")}\n::endgroup::" }

  File.open('error-summary.md', 'w') do |file|
    summary = "# Summary\n\n## Error Summary\n"
    error_messages.each { |message| summary << "\n### #{message.join("\n")}\n" }
    
    if unused_files_message
      puts "::warning::#{unused_files_message}"
      summary << "\n## Warning Summary\n\n#{unused_files_message}\n"
    end
    
    file.write(summary)
  end

  abort
elsif unused_files_message
  puts "::warning::#{unused_files_message}"
end

File.delete('error-summary.md') if File.exist?('error-summary.md')
puts '::notice::All feeds passed checks!'
