# frozen_string_literal: true

require 'iniparser'
require 'faraday'
require 'nokogiri'
require 'uri'

hash = INI.load_file('planet.ini')
av_dir = 'hackergotchi'

avatars = []

hash.each do |key, section|
  next unless section.is_a?(Hash)

  print ":: #{key} =>  "
  feed = section['feed'] if section.key?('feed')
  avatar = section['avatar'] if section.key?('avatar')
  url_arr = []
  url_arr << section['link'] if section.key?('link')
  url_arr << feed if feed
  # Check if avatar exists
  if avatar
    if avatar.include? '//'
      url_arr << avatar
    else
      unless File.file?("#{av_dir}/#{avatar}")
        print "✗\nAvatar not found: hackergotchi/#{avatar}"
        abort
      end
      avatars << avatar
    end
  end
  print '✓ '
  # Check if URLs return 200 status
  url_arr.each do |url|
    res = Faraday.get(URI(url))
    error = "✗\nNon successful status code #{res.status} when trying to access `#{url}`"
    if res.status.to_i.between?(300, 399) && res.headers.key?('location')
      print "#{error}\nTry using `#{res.headers['location']}` instead"
      abort
    end
    unless res.status.to_i == 200
      print error
      abort
    end
  end
  print '✓ '
  # Check is the XML actually parses as XML
  xml = Faraday.get(URI(feed)).body
  xml_err = Nokogiri::XML(xml).errors
  unless xml_err.empty?
    print "✗\nUnusable XML syntax: #{feed}\n#{xml_err}"
    abort
  end
  puts '✓ '
end

avatars << 'default.png'
avatars.uniq!
hackergotchis = Dir.foreach(av_dir).select { |f| File.file?("#{av_dir}/#{f}") }
diff = (hackergotchis - avatars).sort
unless diff.empty?
  print "There are unused files in hackergotchis:\n#{diff.join(', ')}"
  abort
end
