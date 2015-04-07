S3Storage = AWS::S3.new()
TEMP_BUCKET = S3Storage.buckets['test-kl-tmp']