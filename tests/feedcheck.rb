# frozen_string_literal: true

require 'faraday'
require 'iniparser'
require 'nokogiri'
require 'uri'

INI_FILE = 'planet.ini'
AV_DIR = 'hackergotchi'

def check_avatar(avatar, av_dir, faraday)
  return ['_ ', false] if avatar.nil?

  [check_url(avatar, faraday)] if avatar.include? '//'

  ["✗\nAvatar not found: hackergotchi/#{avatar} ", true] unless File.file?("#{av_dir}/#{avatar}")

  ['✓ ', false]
end

def check_url(url, faraday)
  error_message = '✗ '

  begin
    res = faraday.get(URI(url))
  rescue Faraday::ConnectionFailed
    return ["#{error_message}Connection Failure when trying to access '#{url}' ", true]
  rescue Faraday::SSLError
    return ["#{error_message}SSL Error when trying to access '#{url}' ", true]
  end

  error = "#{error_message}Non successful status code #{res.status} when trying to access '#{url}' "
  if res.status.to_i.between?(300, 399) && res.headers.key?('location')
    return ["#{error}\nTry using '#{res.headers['location']}' instead", true]
  end

  [error, true] unless res.status.to_i == 200

  ['✓ ', false]
end

def check_urls(url_arr, faraday)
  results = url_arr.map { |url| check_url(url, faraday) }
  [results.map(&:first).join, results.any?(&:last)]
end

def parse_xml(feed, faraday)
  result = ['✗ ', true]

  begin
    xml = faraday.get(URI(feed))
  rescue Faraday::ConnectionFailed
    ["#{result.first}Connection Failure when trying to read XML from '#{feed}' ", true]
  rescue Faraday::SSLError
    ["#{result.first}SSL Error when trying to read XML from '#{feed}' ", true]
  end

  xml_err = Nokogiri::XML(xml.body).errors
  ["#{result.first}Unusable XML syntax: #{feed}\n#{xml_err} ", true] unless xml_err.empty?

  ['✓ ', false]
end

def check_unused_files(av_dir, avatars)
  hackergotchis = Dir.foreach(av_dir).select { |f| File.file?("#{av_dir}/#{f}") }
  diff = (hackergotchis - avatars)

  [nil, false] if diff.empty? || avatars.empty?

  ["There are unused files in hackergotchis:\n#{diff.join(', ')}", true]
end

def check_source(key, section, faraday)
  did_fail = false
  result = [":: #{key} =>  "]
  avatar = section['avatar'] if section.key?('avatar')

  avatar_result = check_avatar(avatar, AV_DIR, faraday)
  result << avatar_result.first
  did_fail |= avatar_result.last

  link = section['link'] if section.key?('link')
  feed = section['feed'] if section.key?('feed')
  url_result = check_urls([link, feed], faraday)
  result << url_result.first
  did_fail |= url_result.last

  # Only check XML validity if URL checked out ok
  unless url_result.last
    xml_result = parse_xml(feed, faraday)
    result << xml_result.first
    did_fail |= xml_result.last
  end

  [[result.compact.join, did_fail], avatar]
end

planet_srcs = INI.load_file(INI_FILE)
did_any_fail = false
error_messages = []
avatars = ['default.png']

faraday = Faraday.new(request: { open_timeout: 10 }) do |f|
  f.adapter :net_http
end

queue = Queue.new
planet_srcs.each do |key, section|
  queue.push([key, section]) if ARGV.empty? || ARGV.include?(key)
end

workers = (0...3).map do
  Thread.new do
    until queue.empty?
      key, section = queue.pop
      next unless section.is_a?(Hash)

      res, avatar = check_source(key, section, faraday)
      avatars << avatar
      puts res.first if res.first
      error_messages << res.first if res.last
      did_any_fail ||= res.last
    end
  end
end
workers.each(&:join)

unused_files_result = check_unused_files(AV_DIR, avatars)
if unused_files_result.last
  error_messages << unused_files_result.first
  puts "[WARNING] #{unused_files_result.first}"
end

if did_any_fail
  puts "[ERROR] Summary"
  puts error_messages
  abort
end
puts 'All feeds passed checks!'
