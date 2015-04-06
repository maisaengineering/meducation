KIDSLINK = YAML.load_file("#{::Rails.root}/config/kidslink_env.yml")[::Rails.env]
S3Storage = AWS::S3.new()
TEMP_BUCKET = S3Storage.buckets[KIDSLINK["TEMP_BUCKET"]]
HTML_ENTITY = HTMLEntities.new