# frozen_string_literal: true

require 'i18n'

LOCALE_DATA = {}
LOCALE_DATE = {}

module Jekyll
  module Drops
    # Extending class to add locale liquid data
    class UnifiedPayloadDrop
      def locale
        config = @obj.config['localization']
        default_locale = config['locale']
        page_locale = @page['locale'] || { 'id' => default_locale,
                                           'name' => config['locales_set'][default_locale]['name'] }
        locale_dir = '_data/locales'
        current_locale = page_locale['id']
        config['locales_set'].each do |locale, _data|
          next if LOCALE_DATA.key? locale

          LOCALE_DATA[locale] = {}
          locale_file = "#{locale_dir}/#{locale}.yml"
          next unless File.exist?(locale_file)

          YAML.load_file(locale_file).each do |key, value|
            if key == 'locale_date'
              LOCALE_DATE[locale.to_sym] = value
            else
              LOCALE_DATA[locale][key] = value
            end
          end
        end
        Hash(LOCALE_DATA[default_locale]).merge(Hash(LOCALE_DATA[current_locale]))
      end
    end
  end

  # Liquid filter to localize dates
  module Localize
    def localize_date(input, format = :default)
      locale = @context.registers[:page]['locale']['id']
      I18n.available_locales = LOCALE_DATE.keys
      locale = LOCALE_DATE.key?(locale.to_sym) ? locale : 'en'
      LOCALE_DATE.each do |locale, value|
        I18n.backend.store_translations locale, value
      end
      I18n.l(Date.parse(input), format: format, locale: locale.to_sym)
    end
  end
end

Liquid::Template.register_filter(Jekyll::Localize)

# Set up default locale
Jekyll::Hooks.register [:pages, :documents], :pre_render do |document, payload|
  config = document.site.config['localization']

  payload['page']['locale'] ||= { 'id' => config['locale'], 'name' => 'Global' }
  payload['page']['hreflangs'] = config['locales_set'].map do |id, data|
    { 'locale' => { 'id' => id, 'name' => data['name'] }, 'url' => "/#{id}/" }
  end
  payload['page']['locale_siblings'] = payload['page']['hreflangs'].reject do |l|
    l['locale']['id'] == payload['page']['locale']['id']
  end
end
