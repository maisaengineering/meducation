module Mschool
  module CarrierWave
    module StripExifData
      protected
      def strip
        manipulate! do |img|
          begin
            #TODO uncomment while deploying to aws or when solution for exif at heroku is found
            # exif = ::Exif::Data.new(img.path)
            # model.exif_data = exif.to_h.to_json if model.respond_to?(:exif_data) and exif
            img.strip
            img = yield(img) if block_given?
          rescue
            Rails.logger.info "ExifRuntimeError Exception: File not readable or no EXIF data in file"
          end
          img
        end
      end
    end
  end
end