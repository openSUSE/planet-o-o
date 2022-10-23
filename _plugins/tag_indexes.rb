# frozen_string_literal: true

Jekyll::Hooks.register :site, :post_read do |site|
  site.posts.docs.map { |p| p.data['tags'] }.reduce(&:|)&.each do |tag|
    site.pages << TagFeed.new(site, site.source, tag, 'rss20', '.xml')
    site.pages << TagFeed.new(site, site.source, tag, 'atom', '.xml')
    site.pages << TagFeed.new(site, site.source, tag, 'index', '.html')
  end
end

# Generate a paginated tag feed
class TagFeed < Jekyll::Page
  def initialize(site, base, tag, feed, ext)
    super(site, base, '_layouts/', "#{feed}#{ext}")
    @site = site
    @name = "_layouts/#{feed}#{ext}"
    @ext = ext
    @relative_path = "/#{Jekyll::Utils.slugify(tag)}/#{feed + ext}"
    config = site.config['localization']['locales_set']
    read_yaml(File.join(base, '_layouts'), "#{feed}#{ext}")
    page_data(data, tag, feed, ext, config)
  end

  private

  def page_data(data, tag, feed, ext, config)
    data['layout'] = feed
    data['permalink'] = "/#{Jekyll::Utils.slugify(tag)}/"
    data['title'] = config[tag]['name']
    data['language'] = tag
    data['pagination'] = pagination(tag, feed, ext, config)
    data['locale'] = { 'id' => tag, 'name' => config[tag]['name'] }
  end

  def pagination(tag, feed, ext, config)
    {
      'enabled' => true,
      'sort_field' => 'created_at',
      'sort_reverse' => true,
      'tag' => tag,
      'limit' => ext == '.html' ? 0 : 1,
      'indexpage' => feed,
      'extension' => ext.sub('.', ''),
      'title' => config[tag]['name']
    }
  end
end

require 'fileutils'

# Remove the posts from the site
Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob("#{site.dest}/[0-9][0-9][0-9][0-9]").each do |year|
    FileUtils.rm_rf(year)
  end
end
