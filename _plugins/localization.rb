# frozen_string_literal: true

require 'i18n'

module Jekyll
  # Create locale data
  module LocaleData
    class << self
      def locale(config)
        setup(config) unless @locale
        @locale
      end

      def date(config)
        setup(config) unless @locale_date
        @locale_date
      end

      def setup(config)
        @locale ||= {}
        @locale_date ||= {}
        config['locales_set'].each do |lang_id, _data|
          next if @locale.key?(lang_id) && @locale_date.key?(lang_id)

          @locale[lang_id] = {}
          load_data(lang_id)
        end
      end

      def load_data(lang_id)
        locale_file = "_data/locales/#{lang_id}.yml"
        return unless File.exist?(locale_file)

        YAML.load_file(locale_file).each do |key, value|
          if key == 'locale_date'
            @locale_date[lang_id] = value
          else
            @locale[lang_id][key] = value
          end
        end
      end
    end
    private_class_method :load_data
    private_class_method :setup
  end

  module Drops
    # Extending class to add locale liquid data
    class UnifiedPayloadDrop
      def locale
        config = @obj.config['localization']
        default_locale = config['locale']
        page_locale = @page['locale'] || { 'id' => default_locale,
                                           'name' => config['locales_set'][default_locale]['name'] }
        current_locale = page_locale['id']
        locale_data = LocaleData.locale(config)
        Hash(locale_data[default_locale]).merge(Hash(locale_data[current_locale]))
      end
    end
  end

  # Liquid filter to localize dates
  module LocalizeFilters
    def localize_date(input, format = :default)
      page_locale = @context.registers[:page]['locale']['id']
      get_localized_date(Date.parse(input), format, page_locale)
    end

    private

    def get_localized_date(date, format, lang_id)
      config = @context.registers[:site].config['localization']
      fallback_lang_id = config['locale']
      locale_date = LocaleData.date(config)
      locale_list = [fallback_lang_id]
      locale_date.key?(lang_id) ? locale_list << lang_id : lang_id = fallback_lang_id
      I18n.available_locales = locale_list
      locale_list.each do |locale|
        I18n.backend.store_translations locale, locale_date[locale]
      end
      I18n.l(date, format: format, locale: lang_id.to_sym)
    end
  end
end

Liquid::Template.register_filter(Jekyll::LocalizeFilters)

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
