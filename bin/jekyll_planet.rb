# frozen_string_literal: true

require 'pluto/models'
require 'nokogiri'

puts 'db settings:'
@db_config = {
  adapter: 'sqlite3',
  database: './planet.db'
}

pp @db_config

def write_on_file(content, frontmatter, file_name)
  File.open(file_name, 'w') do |f|
    f.write "---\n"
    f.write frontmatter
    f.write "---\n"
    f.write content
  end
end

def file_parameters(item)
  posts_root = './_posts'
  "#{posts_root}/#{parameters_for_file_name(item)}"
end

def fix_html_content(content, item)
  html = Nokogiri::HTML::DocumentFragment.parse(content).to_html
  html.gsub!('{', '&#123;')
  html.gsub!('}', '&#125;')
  html.gsub!(%r{(?<=src=["'])/(?!/)}, "#{%r{//.*?(?=/|$)}.match(item.feed.link)[0]}/")
  html.gsub!(/(?<=src=["'])https?:/, '')

  html
end

def generate_frontmatter(data)
  max_key_length = data.keys.map(&:length).max

  data.reduce('') do |frontmatter, (key, value)|
    spaces = ' ' * (max_key_length + 1 - key.length) unless value.is_a?(Array)
    output = case value
             when Array
               "\n  - \"#{value.join("\"\n  - \"")}\""
             when String
               "\"#{value}\""
             else
               value
             end
    frontmatter + "#{key}:#{spaces}#{output}\n"
  end
end

def sanitize_orignal_link(data)
  data['original_link'] = URI.join(data['link'], data['original_link']).to_s unless data['original_link'].include?('//')
end

def populate_author_contacts(data, item)
  item.feed.author&.split&.each do |contact|
    if contact.include?(':')
      part = contact.split(':')
      data[part.shift] = part.join(':')
    else
      data[contact] = true
    end
  end
end

# rubocop:disable Metrics/AbcSize
def collect_data(item)
  data = {
    'title' => item.title.empty? ? nil : item.title.gsub('"', '\"'),
    'created_at' => item.published,
    'updated_at' => item.updated,
    'guid' => item.guid.empty? ? nil : item.guid,
    'author' => item.feed.title.empty? ? nil : item.feed.title,
    'avatar' => item.feed.avatar,
    'link' => item.feed.link.empty? ? nil : item.feed.link,
    'rss' => item.feed.feed.empty? ? nil : item.feed.feed,
    'tags' => [item.feed.location || 'en'],
    'original_link' => item.url
  }
  populate_author_contacts(data, item)
  sanitize_orignal_link(data)

  data
end
# rubocop:enable Metrics/AbcSize

def parameters_for_file_name(item)
  if item.title.parameterize == ''
    trailing = Digest::SHA2.hexdigest item.content if item.content
    trailing = Digest::SHA2.hexdigest item.summary if item.summary
  else
    trailing = item.title.parameterize
  end
  "#{item.published.strftime('%Y-%m-%d')}-#{trailing}.html"
end

def fix_up_title(title, content)
  content_texts = content ? Nokogiri::HTML::Document.parse(content).search('//text()') : nil
  title = content_texts.first.to_s if content_texts&.first
  title = title.to_s.split('.').first if title
  title = title.to_s[0..255] if title

  title
end

def prepare_item(item)
  item.published = item.updated if item.published.nil?
  item.title = fix_up_title(item.title, (item.content || item.summary)) if item.title == ''

  posts_root = './_posts'
  FileUtils.mkdir_p(posts_root) # ensure path exists
end

def item_valid?(item)
  item.title && item.published && item.url && (item.content || item.summary)
end

def generate_blog_post(item)
  return unless item_valid?(item)

  prepare_item(item)
  data = collect_data(item)
  frontmatter = generate_frontmatter(data)
  html = fix_html_content(item.content || item.summary, item)

  write_on_file(html, frontmatter, file_parameters(item))
end

def handle_blog_post(item, index)
  puts "[#{index + 1}] #{item.title}"

  generate_blog_post(item)
rescue StandardError => e
  puts "::warning::Failed to generate blog post for #{item.title}. Error: #{e.message}"
end

def generate_posts
  latest_items = Pluto::Model::Item.latest
  puts "::notice::Total of #{latest_items.size} blog posts generated"

  latest_items.each_with_index do |item, i|
    handle_blog_post(item, i)
  end
end

def handle_database
  database_path = @db_config[:database]
  return if File.exist?(database_path)

  abort "::error::database #{database_path} missing; please check pluto documentation for importing feeds etc."
end

def run(_args)
  handle_database
  Pluto.connect(@db_config)

  generate_posts
end

run ARGV
