IMGKit.configure do |config|
  if Rails.env.production?
    config.wkhtmltoimage =   Rails.root.join('lib', 'wkhtmltoimage-amd64').to_s
  else
    config.wkhtmltoimage = '/usr/local/bin/wkhtmltoimage'
  end
end

#IMGKit.configure do |config|
#  config.wkhtmltoimage = '/usr/local/bin/wkhtmltoimage/wkhtmltoimage-i386'
#  config.default_options = {
#      quality: 70,
#      encoding: 'UTF-8'
#  }
#  config.default_format = :jpg
#end