# frozen_string_literal: true

require 'faraday'
require 'nokogiri'
require 'uri'

class Status
  FAILED = true
  PASSED = false
end

def check_avatar(avatar, av_dir, faraday)
  return ['_ ', Status::PASSED] unless avatar

  return check_url(avatar, faraday) if avatar.include? '//'
  return ["✗ Avatar not found: #{av_dir}/#{avatar} ", Status::FAILED] unless File.file?("#{av_dir}/#{avatar}")

  ['✓ ', Status::PASSED]
end

def check_url(url, faraday)
  error_message = '✗ '

  begin
    res = faraday.get(URI(url))
  rescue Faraday::ConnectionFailed
    return ["#{error_message}Connection Failure when trying to access '#{url}' ", Status::FAILED]
  rescue Faraday::TimeoutError
    return ["#{error_message}Connection Timeout waiting for '#{url}' ", Status::FAILED]
  rescue Faraday::SSLError
    return ["#{error_message}SSL Error when trying to access '#{url}' ", Status::FAILED]
  end

  error = "#{error_message}Non successful status code #{res.status} when trying to access '#{url}' "
  if res.status.to_i.between?(300, 399) && res.headers.key?('location')
    return ["#{error}. Try using '#{res.headers['location']}' instead", Status::FAILED]
  end

  return [error, Status::FAILED] unless res.status.to_i == 200

  ['✓ ', Status::PASSED]
end

def check_urls(url_arr, faraday)
  results = url_arr.map { |url| check_url(url, faraday) }

  [results.map(&:first).join, results.any?(&:last)]
end

def parse_xml(feed, faraday)
  result = ['✗ ', Status::FAILED]

  begin
    xml = faraday.get(URI(feed))
  rescue Faraday::ConnectionFailed
    return ["#{result.first}Connection Failure when trying to read XML from '#{feed}' ", Status::FAILED]
  rescue Faraday::SSLError
    return ["#{result.first}SSL Error when trying to read XML from '#{feed}' ", Status::FAILED]
  end

  xml_err = Nokogiri::XML(xml.body).errors
  return ["#{result.first}Unusable XML syntax: #{feed}\n#{xml_err} ", Status::FAILED] unless xml_err.empty?

  ['✓ ', Status::PASSED]
end

def check_unused_files(av_dir, avatars)
  hackergotchis = Dir.foreach(av_dir).select { |f| File.file?("#{av_dir}/#{f}") }
  diff = (hackergotchis - avatars)

  return ["There are unused files in #{av_dir}: #{diff.sort.join(', ')}", Status::FAILED] unless diff.empty?

  [nil, Status::PASSED]
end

def accumulate_results(result, did_fail, new_result)
  result << new_result.first

  did_fail | new_result.last
end

def check_source(key, section, faraday)
  result = [":: #{key} =>  "]
  avatar, link, feed = %w[avatar link feed].map { |k| section[k] if section.key?(k) }

  avatar_result = check_avatar(avatar, AV_DIR, faraday)
  did_fail = accumulate_results(result, Status::PASSED, avatar_result)

  url_result = check_urls([link, feed], faraday)
  did_fail = accumulate_results(result, did_fail, url_result)

  xml_result = url_result.last ? ['_ ', Status::PASSED] : parse_xml(feed, faraday)
  did_fail = accumulate_results(result, did_fail, xml_result)

  [[result.compact.join, did_fail], avatar]
end
