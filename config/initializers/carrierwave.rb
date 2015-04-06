CarrierWave.configure do |config|
  #config.storage = :grid_fs
  config.grid_fs_access_url = "/uploads"
  config.fog_credentials = { provider: 'AWS',aws_access_key_id: ENV["AWS_ACCESS_KEY_ID"], aws_secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"]}
  # config.fog_directory  = "name_of_bucket" # required
  # config.fog_public     = false                                   # optional, defaults to true
  config.fog_attributes = {'Cache-Control'=>'max-age=315360000'}  # optional, defaults to {}
  config.cache_dir = "#{Rails.root}/tmp/uploads"
  config.asset_host = ENV['CDN_URL']
end


AWS.config(access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])