# frozen_string_literal: true

require 'faraday'
require 'rss'
require 'uri'

# Statuses for check results, with associated symbols
module Status
  FAILED = :failed
  SKIPPED = :skipped
  PASSED = :passed

  PREFIX = {
    PASSED => '✓ ',
    FAILED => '✗ ',
    SKIPPED => '~ '
  }.freeze
end

# Data structure for results of an individual check
CheckResult = Struct.new(:status, :message) do
  def failed?
    status == Status::FAILED
  end
end

# Data structure for results of all checks for a given feed
SourceResult = Struct.new(:feed_name, :symbols, :error_messages, :failed, :avatar, keyword_init: true)

def check_status_and_location(response)
  status = response.status.to_i
  location = response.headers['location']
  base_error = "Status code #{status}"

  if status.between?(300, 399) && location
    begin
      uri = URI.parse(location)
    rescue
      uri = nil
    end

    if uri&.host&.end_with?('google.com') && uri&.path == '/sorry/index'
      return CheckResult.new(Status::SKIPPED, "#{base_error} (google bot challenge) ")
    end

    return CheckResult.new(Status::FAILED, "#{base_error} (redirect to '#{location}') ")
  end

  return CheckResult.new(Status::FAILED, "#{base_error} (access denied) ") if status == 403

  return CheckResult.new(Status::FAILED, base_error) unless status == 200

  CheckResult.new(Status::PASSED)
end

def request_data(connection, url)
  connection.get(URI(url))
rescue Faraday::ConnectionFailed, Faraday::TimeoutError, Faraday::SSLError => e
  CheckResult.new(Status::FAILED, "#{e.class} when trying to access '#{url}' ")
end

def parse_feed(feed, faraday)
  response = request_data(faraday, feed)
  return response if response.is_a?(CheckResult)

  begin
    parsed_feed = RSS::Parser.parse(response.body, false)
    return CheckResult.new(Status::FAILED, 'Unparseable feed format ') unless parsed_feed
  rescue RSS::Error => e
    return CheckResult.new(Status::FAILED, "Unusable Feed syntax: #{feed} (#{e.message}) ")
  end

  CheckResult.new(Status::PASSED)
end

def check_single_url(url, faraday)
  response = request_data(faraday, url)
  return response if response.is_a?(CheckResult)

  check_status_and_location(response)
end

def check_avatar(avatar, av_dir, faraday)
  return CheckResult.new(Status::SKIPPED) unless avatar
  return check_single_url(avatar, faraday) if avatar.include?('//')

  avatar_path = "#{av_dir}/#{avatar}"
  return CheckResult.new(Status::FAILED, "Avatar not found: #{avatar_path} ") unless File.file?(avatar_path)

  CheckResult.new(Status::PASSED)
end

class SourceChecks
  def initialize
    @results = {}
  end

  def add(label, result)
    @results[label] = result
  end

  def failed?
    @results.each_value.any?(&:failed?)
  end

  def symbols
    @results.each_value.map { |result| Status::PREFIX[result.status] }.join
  end

  def error_messages
    @results.filter_map do |label, result|
      "#{label}: #{result.message.strip}" if result.failed? && result.message
    end
  end
end

def check_source(feed_name, section, faraday, avatar_directory)
  avatar, link, feed = %w[avatar link feed].map { |k| section[k] }

  checks = SourceChecks.new
  checks.add('avatar', check_avatar(avatar, avatar_directory, faraday))

  link_result = check_single_url(link, faraday)
  feed_result = check_single_url(feed, faraday)
  checks.add('link', link_result)
  checks.add('feed', feed_result)

  xml_result = if link_result.failed? || feed_result.failed?
                 CheckResult.new(Status::SKIPPED)
               else
                 parse_feed(feed, faraday)
               end
  checks.add('xml', xml_result)

  SourceResult.new(
    feed_name: feed_name,
    symbols: checks.symbols,
    error_messages: checks.error_messages,
    failed: checks.failed?,
    avatar: avatar
  )
end

def check_unused_files(avatar_directory, expected_avatars)
  avatar_files = Dir.foreach(avatar_directory).select { |f| File.file?("#{avatar_directory}/#{f}") }
  diff = avatar_files - expected_avatars

  return nil if diff.empty?

  "There are unused files in #{avatar_directory}: #{diff.sort.join(', ')}"
end
