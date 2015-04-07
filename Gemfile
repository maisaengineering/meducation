source 'https://rubygems.org'
ruby '2.0.0'

gem 'rails', '4.0.9'
gem 'rest-client'

gem 'sass-rails', '~> 4.0.0'
gem 'coffee-rails', '~> 4.0.0'
gem 'uglifier'
gem 'jquery-rails', '2.1.4'
gem 'jquery-ui-rails'
gem 'turbolinks'
gem 'therubyracer', '0.12.0', :platform => :ruby
gem "yui-compressor", "~> 0.12.0"
gem "heroku"
gem "heroku-api"

group :production do 
  gem 'heroku_rails_deflate' # Only for heroku
  # Rails Server
  gem 'unicorn'
  gem 'rails_12factor', group: :production
end

group :development, :test do
  gem 'bullet'
  gem 'faker'
  gem 'letter_opener' #Preview email in the browser instead of sending it
  gem "brakeman", :require => false
  gem 'thin'
  gem 'mongoid-rspec'
  gem 'rspec-rails'
  gem "database_cleaner"
  gem 'factory_girl_rails'
  gem 'cucumber'
  gem 'capybara'
  gem 'launchy'
  gem 'newrelic_rpm', '3.8.0.218'
  gem 'newrelic_moped', '0.0.11'
  gem 'debugger'

end

gem 'libv8', '3.16.14.3'
gem 'rufus-scheduler'
gem "mongoid" ,'~> 4', github: 'mongoid/mongoid', ref: '9b3bc1264032209b7a6c0e82d0ca656f401e476b'
gem "geocoder"#, git: "git://github.com/alexreisner/geocoder.git"
gem "devise", "~> 3.2.1"
gem 'cancan'
gem 'haml'
gem "json", "~> 1.7.3"
gem "braintree",'2.6.1'
gem 'to_csv-rails'
gem 'will_paginate_mongoid'
gem 'carrierwave'
gem "carrierwave-mongoid", git: "git://github.com/jnicklas/carrierwave-mongoid.git"
gem 'mini_magick'
gem 'delayed_job_mongoid', github: 'maisaengineering/delayed_job_mongoid'
gem 'mongoid_taggable'
gem 'mongoid-tree','~> 1.0.4', :require => 'mongoid/tree'
gem 'handlebars' # for dynamic templates
gem 'imgkit' # convert html into image
gem "dotiw", github: 'maisaengineering/dotiw' # better distance_of_time_in_words
#gem 'rubyzip'
gem "daemons"
gem "cocoon"
gem 'remotipart', '1.2.1'
gem 'omniauth-facebook'
gem 'koala', '1.8.0'
gem 'exception_notification'
gem "fog"#, "~> 1.3.1" #Carrierwave AWS-S3 file storage
gem 'unf' # To remove "fog" warning, "[fog][WARNING] Unable to load the 'unf' gem. Your AWS strings may not be properly encoded."
gem "mobile-fu", "~> 1.2.1" #Mobile request identifier
gem 'protected_attributes'
gem "moped", github: 'mongoid/moped', branch: 'master'
gem 'rubyzip', '>= 1.0.0' # will load new rubyzip version
gem 'zip-zip' # will load compatibility for old rubyzip API.
gem 'axlsx', '~> 2.0.1'
gem 'axlsx_rails'

#gem 'doorkeeper', github: 'maisaengineering/doorkeeper'
gem 'mongo_session_store-rails4', '5.1.0'
gem 'jquery-turbolinks'
gem 'mongoid_slug', '~> 3.2.1'
gem 'zeroclipboard-rails'
gem 'aws-sdk', '~> 2.0'
gem 'aws-sdk-v1'
gem 'figaro'

# http://richonrails.com/articles/ip-geolocation-in-ruby-on-rails
# for maxmind free geoIp lookup
gem 'geoip' #https://github.com/cjheath/geoip
gem 'spreadsheet'
#TODO uncomment while deploying to aws
#TODO need to find solution to install exif on heroku
# gem 'exif' # https://github.com/tonytonyjan/exif


gem 'rename'