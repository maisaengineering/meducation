module Mschool
  module CarrierWave
    module CdnVersions

      require 'rest-client'

      def preload_image_to_cdn(version =nil)
        versions = version ? version.split(',').map(&:strip) : send(:versions).keys.push(nil)
        versions.each do|version|
          version = nil if version.to_s.eql?("original")
          open(version ? send(version.to_sym).url : url)
        end
      end

      def file_exists?
        begin
          RestClient.head(url) do |response, request, result, &block|
            response.code == 200
          end
        rescue
          false
        end
      end

    end
  end
end
