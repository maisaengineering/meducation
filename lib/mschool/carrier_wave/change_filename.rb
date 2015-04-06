module Mschool
  module CarrierWave
    module ChangeFilename
      # refer : https://github.com/carrierwaveuploader/carrierwave/wiki/How-to%3A-Create-random-and-unique-filenames-for-all-versioned-files
      # In order to save the newly generated filename you have to call save! on the model after recreate_versions!
      def filename
        if original_filename
          # If you want to keep the previously encoded name when recreating the versions
          # i.e don't update the filename on edit(recreating_versions!)
          if model && model.read_attribute(mounted_as).present?
            if (model.respond_to?(:doc_ids) and model.read_attribute(mounted_as).eql?('_old_')) or model.instance_eval("#{mounted_as}_changed?")
              "#{secure_token}.#{file.extension}"
            else
              model.read_attribute(mounted_as)
            end
          else
            "#{secure_token}.#{file.extension}" #if original_filename.present?
          end
        end
      end

      protected
      def secure_token
        var = :"@#{mounted_as}_secure_token"
        chunk = model.send(mounted_as)
        begin
          md5 = Digest::MD5.hexdigest(chunk.read)
        rescue
          md5 = Digest::MD5.hexdigest(Time.now.strftime("%Y%m%d%H%M%S%L-%12N"))
        end
        model.instance_variable_get(var) or model.instance_variable_set(var, md5)
      end
    end
  end
end