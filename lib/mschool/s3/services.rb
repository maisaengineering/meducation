module Mschool
  module S3
    module Services

      def upload_file(params, klass=Activity)
        extention = params[:name].split('.').last.strip
        content = Base64.decode64(params[:content].split(',').last)
        md5 = Digest::MD5.hexdigest(content)
        key =  "uploads/#{md5}.#{extention}".split('.').reject(&:blank?).join(".")
        MultiMediaMetaData.create(key: key, processing: true)
        Delayed::Job.enqueue StripExifDataJob.new(klass, key), queue: "stripExif", priority: 0
        TEMP_BUCKET.objects[key].write(content, :acl => :public_read)
      end


      def copy_file(source_key, target_key, target_bucket_name =nil, source_bucket_name=nil)
        source_bucket= source_bucket_name ? S3Storage.buckets[source_bucket_name] : TEMP_BUCKET
        source = source_bucket.objects[source_key]
        target = S3Storage.buckets[target_bucket_name].objects[target_key]
        source.copy_to(target)
        target.acl = :public_read
        target
      end

    end
  end
end
