Jekyll::Hooks.register :site, :post_read do |site|
  site.posts.docs.map { |p| p.data['tags'] }.reduce(&:|)&.each do |tag|
    site.pages << TagFeed.new(site, site.source, tag, 'rss20', '.xml')
    site.pages << TagFeed.new(site, site.source, tag, 'atom', '.xml')
    site.pages << TagFeed.new(site, site.source, tag, 'index', '.html')
  end
end

class TagFeed < Jekyll::Page
  def initialize(site, base, tag, feed, ext)
    @site = site
    @name = "_layouts/#{feed}#{ext}"
    @ext = ext
    @relative_path = "/#{Jekyll::Utils.slugify(tag)}/#{feed + ext}"
    config = site.config['localization']['locales_set']

    self.read_yaml(File.join(base, '_layouts'), "#{feed}#{ext}")
    self.data['layout'] = feed
    self.data['permalink'] = "/#{Jekyll::Utils.slugify(tag)}/"
    self.data['title'] = config[tag]["name"]
    self.data['language'] = tag
    self.data['pagination'] = {
      'enabled' => true,
      'sort_field' => 'created_at',
      'sort_reverse' => true,
      'tag' => tag,
      'limit' => ext == '.html' ? 0 : 1,
      'indexpage' => feed,
      'extension' => ext.sub('.',''),
      'title' => config[tag]["name"]
    }
    self.data['locale'] = { 'id' => tag, 'name' => config[tag]["name"] }
  end
end

require 'i18n'

LOCALE_DATA = {}
LOCALE_DATE = {}

module Jekyll
  module Utils
    extend self

    def snakeify(input)
      slug = slugify(input.to_s, :mode => "latin", :cased => true)
      slug.tr!("-", "_")
      slug
    end
  end
  class Drops::UnifiedPayloadDrop
    def locale
      config = @obj.config['localization']
      default_locale = Utils.snakeify(config['locale'])
      page_locale = @page['locale'] || { 'id' => default_locale, 'name' => config['locales_set'][default_locale]['name'] }
      locale_dir = '_data/locales'
      current_locale = Utils.snakeify(page_locale['id'])
      snakeified_keys = {}
      config['locales_set'].each do |locale, data|
        locale = Utils.snakeify(locale)
        unless LOCALE_DATA.has_key? locale
          LOCALE_DATA[locale] = {}
          locale_file = "#{locale_dir}/#{locale}.yml"
          YAML.load_file(locale_file).each do |key, value|
            if key == 'locale_date'
              LOCALE_DATE[locale.to_sym] = value
            else
              snakeified_keys[key] = snakeified_keys.has_key?(key) ? snakeified_keys[key] : Utils.snakeify(key)
              LOCALE_DATA[locale][snakeified_keys[key]] = value
            end
          end if File.exists?(locale_file)
        end
      end
      Hash(LOCALE_DATA[default_locale]).merge(Hash(LOCALE_DATA[current_locale]))
    end
  end
end

module Jekyll
  module LocalizeDateFilter
    def localize_date(input, format = :default)
      locale = @context.registers[:page]['locale']['id']
      I18n.available_locales = LOCALE_DATE.keys
      locale = LOCALE_DATE.has_key?(locale.to_sym) ? locale : 'en'
      LOCALE_DATE.each do |locale, value|
        I18n.backend.store_translations locale, recursive_symbolize_keys(value)
      end
      I18n.l(Date.parse(input), :format => format, :locale => locale.to_sym)
    end

  private

    def recursive_symbolize_keys(h)
      case h
      when Hash
        Hash[
          h.map do |k, v|
            [ k.respond_to?(:to_sym) ? k.to_sym : k, recursive_symbolize_keys(v) ]
          end
        ]
      when Enumerable
        h.map { |v| recursive_symbolize_keys(v) }
      else
        h
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::LocalizeDateFilter)

# Set up default locale
Jekyll::Hooks.register [:pages, :documents], :pre_render do |document, payload|
  config = document.site.config['localization']
  
  payload["page"]["locale"] ||= { 'id' => config['locale'], 'name' => 'Global' } 
  payload["page"]["hreflangs"] = config['locales_set'].map {|id, data| {'locale' => { 'id' => id, 'name' => data['name'] }, 'url' => "/#{id}/"} }
  payload["page"]["locale_siblings"] = payload["page"]["hreflangs"].reject {|l| l['locale']['id'] == payload["page"]["locale"]['id'] }
end

require 'fileutils'

# Remove the posts from the site
Jekyll::Hooks.register :site, :post_write do |site|
  Dir.glob("#{site.dest}/[0-9][0-9][0-9][0-9]").each do |year|
    FileUtils.rm_rf(year)
  end
end
