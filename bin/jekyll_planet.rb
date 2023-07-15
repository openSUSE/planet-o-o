# frozen_string_literal: true

require 'pluto/models'
require 'nokogiri'

puts 'db settings:'
@db_config = {
  adapter: 'sqlite3',
  database: './planet.db'
}

pp @db_config

def run(_args)
  unless File.exist?(@db_config[:database])
    puts "** error: database #{@db_config[:database]} missing; please check pluto documention for importing feeds etc."
    exit 1
  end

  Pluto.connect(@db_config)

  Pluto::Model::Item.latest.each_with_index do |item, i|
    puts "[#{i + 1}] #{item.title}"

    generate_blog_post(item)
  end
end

def generate_frontmatter(data)
  frontmatter = ''
  data.each do |key, value|
    spaces = ' ' * (data.keys.map(&:length).max + 1 - key.length) unless value.is_a?(Array)
    output = value
    output = "\"#{value}\"" if value.is_a?(String)
    output = "\n  - \"#{value.join("\"\n  - \"")}\"" if value.is_a?(Array)
    frontmatter += "#{key}:#{spaces}#{output}\n"
  end
  frontmatter
end

def fix_up_title(title, content)
  title = Nokogiri::HTML::Document.parse(content).search('//text()').first if content
  title = title.to_s.slice(0..(title.to_s.index('.'))) if title
  title = title.to_s.slice(0..255) if title
  title
end

def generate_blog_post(item)
  posts_root = './_posts'

  FileUtils.mkdir_p(posts_root) ## make sure path exists

  item.published = item.updated if item.published.nil?

  content = item.content || item.summary

  item.title = fix_up_title(item.title, content) if item.title == ''

  return unless item.title && item.published && item.url && content

  ## Note:
  ## Jekyll pattern for blogs must follow
  ##  2014-12-21-  e.g. must include trailing dash (-)
  if item.title.parameterize == ''
    trailing = Digest::SHA2.hexdigest item.content if item.content
    trailing = Digest::SHA2.hexdigest item.summary if item.summary
  else
    trailing = item.title.parameterize
  end
  fn = "#{posts_root}/#{item.published.strftime('%Y-%m-%d')}-#{trailing}.html"
  # Check for author tags

  data = {}
  data['title'] = item.title.gsub('"', '\"') unless item.title.empty?
  data['created_at'] = item.published if item.published
  data['updated_at'] = item.updated if item.updated
  data['guid'] = item.guid unless item.guid.empty?
  data['author'] = item.feed.title unless item.feed.title.empty?
  data['avatar'] = item.feed.avatar if item.feed.avatar
  data['link'] = item.feed.link unless item.feed.link.empty?
  data['rss'] = item.feed.feed unless item.feed.feed.empty?
  data['tags'] = [item.feed.location || 'en']
  data['original_link'] = item.url if item.url
  item.feed.author&.split&.each do |contact|
    if contact.include?(':')
      part = contact.split(':')
      data[part.shift] = part.join(':')
    else
      data[contact] = true
    end
  end
  data['original_link'] = URI.join(data['link'], data['original_link']).to_s unless data['original_link'].include?('//')
  frontmatter = generate_frontmatter(data)

  File.open(fn, 'w') do |f|
    f.write "---\n"
    f.write frontmatter
    f.write "---\n"

    # There were a few issues of incomplete html documents, nokogiri fixes that
    html = Nokogiri::HTML::DocumentFragment.parse(content).to_html
    # Liquid complains about curly braces
    html.gsub!('{', '&#123;')
    html.gsub!('}', '&#125;')
    html.gsub!(%r{(?<=src=["'])/(?!/)}, "#{%r{//.*?(?=/|$)}.match(item.feed.link)[0]}/")
    html.gsub!(/(?<=src=["'])https?:/, '')
    f.write html
  end
end

run(ARGV)
