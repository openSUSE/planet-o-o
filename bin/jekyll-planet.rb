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

  Pluto::Model::Item.latest.limit(1000).each_with_index do |item,i|
    puts "[#{i+1}] #{item.title}"

    generate_blog_post( item )
  end
end


def generate_blog_post( item )

  posts_root = "./_posts"

  FileUtils.mkdir_p( posts_root )  ## make sure path exists

  ## Note:
  ## Jekyll pattern for blogs must follow
  ##  2014-12-21-  e.g. must include trailing dash (-)
  fn = "#{posts_root}/#{item.published.strftime('%Y-%m-%d')}-#{item.title.parameterize}.html"
  # Check for author tags

  frontmatter =<<EOS
title:      "#{item.title.gsub("\"","\\\"")}"
created_at: #{item.published}
updated_at: #{item.updated}
guid:       #{item.guid}
author:     #{item.feed.title}
avatar:     #{item.feed.avatar}
link:       #{item.feed.link}
rss:        #{item.feed.feed}
tags:
  - #{item.feed.location ? item.feed.location : "en"}
original_link: "#{item.url unless item.url.empty?}"
EOS

  item.feed.author.split.each do |contact|
    if contact.include?(':')
      part = contact.split(':')
      frontmatter += "#{part.shift}: \"#{part.join(':')}\""
    else
      frontmatter += "#{contact}: true"
    end
  end if item.feed.author


  File.open( fn, 'w' ) do |f|
    f.write '---'
    f.write frontmatter
    f.write '---'

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
    f.write html
  end
end

run( ARGV )

