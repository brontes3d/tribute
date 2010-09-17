# http://www.iso.org/iso/iso-3166-1_decoding_table
# http://github.com/koke/iso_countries/raw/master/lib/country_list.rb
module ISO
  module Countries
    
    def self.[](key)
      self.countries[key.to_s.downcase.to_sym]
    end
    
    def self.countries
      @@countries ||= {
        :at => I18n.t("country_code.at"),
        :be => I18n.t("country_code.be"),
        :ca => I18n.t("country_code.ca"),
        :ch => I18n.t("country_code.ch"),
        :de => I18n.t("country_code.de"),
        :es => I18n.t("country_code.es"),
        :fr => I18n.t("country_code.fr"),
        :gb => I18n.t("country_code.gb"),
        :il => I18n.t("country_code.il"),
        :it => I18n.t("country_code.it"),
        :nl => I18n.t("country_code.nl"),
        :se => I18n.t("country_code.se"),
        :us => I18n.t("country_code.us"),
      }
    end
    
  end
end