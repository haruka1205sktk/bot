require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class Language < ActiveRecord::Base
end