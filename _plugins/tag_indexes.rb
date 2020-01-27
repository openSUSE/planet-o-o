Jekyll::Hooks.register :site, :post_read do |site|
  site.posts.docs.map { |p| p.data['tags'] }.reduce(&:|)&.each do |tag|
    site.pages << TagFeed.new(site, site.source, tag, 'rss20', '.xml', 1)
    site.pages << TagFeed.new(site, site.source, tag, 'atom', '.xml', 1)
    # This will not be needed when the autopages are fixed
    site.pages << TagFeed.new(site, site.source, tag, 'index', '.html', 0)
  end
end

class TagFeed < Jekyll::Page
  def initialize(site, base, tag, feed, ext, limit)
    @site = site
    @name = "_layouts/#{feed}#{ext}"
    @ext = ext

    self.read_yaml(File.join(base, '_layouts'), "#{feed}#{ext}")
    self.data['layout'] = feed
    self.data['permalink'] = "/#{Jekyll::Utils.slugify(tag)}/#{feed + ext unless limit != 1}"
    self.data['title'] = tag
    self.data['pagination'] = {
      'enabled' => true,
      'sort_field' => 'created_at',
      'sort_reverse' => true,
      'tag' => tag,
      'limit' => limit,
      'title' => ':title'
    }
  end
end
