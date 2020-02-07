# encoding: utf-8
require 'pluto/models'
require 'nokogiri'

puts "db settings:"
@db_config = {
  adapter: 'sqlite3',
  database: './planet.db'
}

pp @db_config


def run( args )
  unless File.exists?( @db_config[:database])
    puts "** error: database #{@db_config[:database]} missing; please check pluto documention for importing feeds etc."
    exit 1;
  end

  Pluto.connect( @db_config )

  Pluto::Model::Item.latest.where.not(title: '', published: nil).limit(1000).each_with_index do |item,i|
    puts "[#{i+1}] #{item.title}"

    generate_blog_post( item )
  end
end

def generate_frontmatter( data )

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

def generate_blog_post( item )

  posts_root = "./_posts"

  FileUtils.mkdir_p( posts_root )  ## make sure path exists

  ## Note:
  ## Jekyll pattern for blogs must follow
  ##  2014-12-21-  e.g. must include trailing dash (-)
  fn = "#{posts_root}/#{item.published.strftime('%Y-%m-%d')}-#{item.title.parameterize}.html"
  # Check for author tags

  data = {}
  data["title"] = item.title.gsub('"','\"') unless item.title.empty?
  data["created_at"] = item.published if item.published
  data["updated_at"] = item.updated if item.updated
  data["guid"] = item.guid unless item.guid.empty?
  data["author"] = item.feed.title unless item.feed.title.empty?
  data["avatar"] = item.feed.avatar if item.feed.avatar
  data["link"] = item.feed.link unless item.feed.link.empty?
  data["rss"] = item.feed.feed unless item.feed.feed.empty?
  data["tags"] = [ item.feed.location ? item.feed.location : "en" ]
  data["original_link"] = item.url if item.url
  item.feed.author.split.each do |contact|
    if contact.include?(':')
      part = contact.split(':')
      data[part.shift] = part.join(':')
    else
      data[contact] = true
    end
  end if item.feed.author
  frontmatter = generate_frontmatter(data)

  File.open( fn, 'w' ) do |f|
    f.write "---\n"
    f.write frontmatter
    f.write "---\n"

    # There were a few issues of incomplete html documents, nokogiri fixes that
    html = ""
    if item.content
      html = Nokogiri::HTML::DocumentFragment.parse(item.content).to_html
    elsif item.summary
      html = Nokogiri::HTML::DocumentFragment.parse(item.summary).to_html
    else
      ## warn: not content found for feed
    end
    # Liquid complains about curly braces
    html.gsub!("{", "&#123;")
    html.gsub!("{", "&#125;")
    html.gsub!(/(?<=src=[\"\'])\/(?!\/)/, "#{/\/\/.*?(?=\/|$)/.match(item.feed.link)[0]}/")
    html.gsub!(/(?<=src=[\"\'])https?:/, "")
    f.write html
  end
end

run( ARGV )

