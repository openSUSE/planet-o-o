# encoding: utf-8


module JekyllPlanet

class Tool

  def initialize()
    puts "db settings:"
    @db_config = {
      adapter: 'sqlite3',
      database: './planet.db'
    }

    pp @db_config
  end


  def run( args )
    unless File.exists?( @db_config[:database])
      puts "** error: database #{@db_config[:database]} missing; please check pluto documention for importing feeds etc."
      exit 1;
    end

    Pluto.connect( @db_config )

    Pluto::Model::Item.latest.limit(200).each_with_index do |item,i|
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
    fn = "#{posts_root}/#{item.published.strftime('%Y-%m-%d')}-#{title_to_key(item.title)}.html"
    # Check for author tags
    if item.feed.author
      author = item.feed.author.split
      irc = author.select{|a| a.start_with?("irc:")}.first.delete_prefix("irc:") if author.any?{|a| a.start_with?("irc:")}
      connect = author.select{|a| a.start_with?("connect:")}.first.delete_prefix("connect:") if author.any?{|a| a.start_with?("connect:")}
      member = author.any?{|a| a == "member"}
      gsoc = author.any?{|a| a == "gsoc"}
    end

    frontmatter =<<EOS
---
title:      "#{item.title.gsub("\"","\\\"")}"
created_at: #{item.published}
author:     #{item.feed.title}
avatar:     #{item.feed.avatar}
link:       #{item.feed.link}
rss:        #{item.feed.feed}
EOS

frontmatter += "irc:        \"#{irc}\"\n" unless irc.nil?
frontmatter += "connect:    \"#{connect}\"\n" unless connect.nil?
frontmatter += "member:     #{member}\n" unless member.nil?
frontmatter += "gsoc:       #{gsoc}\n" unless gsoc.nil?

frontmatter +=<<EOS
tags:       #{item.feed.location ? item.feed.location : "en"}
original_link: "#{item.url unless item.url.empty?}"
---
EOS


    File.open( fn, 'w' ) do |f|
      f.write frontmatter

      # There were a few issues of incomplete html documents, nokogiri fixes that
      html = ""
      if item.content
        html = Nokogiri::HTML::DocumentFragment.parse(item.content).to_html
      elsif item.summary
        html = Nokogiri::HTML::DocumentFragment.parse(item.summary).to_html
      else
        ## warn: not content found for feed
      end
      html.gsub!("{", "&#123;")
      html.gsub!("{", "&#125;")
      f.write html
    end
  end


private

def title_to_key( title )
  
  ### fix: use textutils.title_to_key ??
  key = title.downcase
  key = key.gsub( 'ü', 'ue' )
  key = key.gsub( 'é', 'e' )

  key = key.gsub( /[^a-z0-9\- ]/, '' )  ## for now remove all chars except a-z and 0-9
  key = key.strip
  key = key.gsub( /[ ]+/, '_' )

  if key.blank?   ## note: might result in null string (use timestamp)
    key = "post#{Time.now.strftime('%Y%m%d%H%M%S%L')}"
  end

  key
end

end  ## class Tool
end ## module JekyllPlanet

