# Need this here so its loaded with the Workling workers 
#(TODO: we want it to load every request in dev and load only once in production)
# LadyTribute.load_business
require_dependency 'lady_tribute'

#LOAD business initializers
# Dir.glob("#{RAILS_ROOT}/business/config/initializers/*.rb").each { |f| require f }

#LOAD business locales/translations
# Dir.glob("#{RAILS_ROOT}/business/config/locales/*.yml").each { |f| I18n.load_path << f }
