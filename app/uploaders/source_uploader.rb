# encoding: utf-8
require 'carrierwave/processing/mini_magick'
require 'carrierwave/processing/mime_types'
class SourceUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick
  include CarrierWave::MiniMagick
  #include Sprockets::Helpers::RailsHelper  #Rails4.0 removed
  #include Sprockets::Helpers::IsolatedHelper
  include CarrierWave::MimeTypes
  #update original filename with timestamp with picoseconds
  include Mschool::CarrierWave::StripExifData
  include Mschool::CarrierWave::ChangeFilename
  include Mschool::CarrierWave::CdnVersions

  #delay versions as background
  #include ::CarrierWave::Backgrounder::Delay
  #for multiple upload pdf.

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  # include Sprockets::Helpers::RailsHelper
  # include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  #storage :file
  storage :fog
  process :strip
  # storage :fog
  process :image_rotation
  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:

  def store_dir
    "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  #def store_dir
  #  "pictures/#{mounted_as}/#{model.id}"
  #end
  #
  ## If Logo is for Organization use organization bucket else Hospital Bucket ...
  def fog_directory
    'test-kl-tmp'
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:

  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :scale => [50, 50]
  # end
  # Create different versions of your uploaded files:
  #process :resize_to_fit => [800, 800]

  version :thumb, if: :is_multi?  do
    process resize_to_fill: [230,336]

  end

  #version :mini, if: :is_multi? do
  #  process resize_to_fill: [70, 99]
  #end
  #


  def cropping(w,h)
    manipulate! do |image|
      image.tap(&:auto_orient)
      w_original = image[:width].to_f
      h_original = image[:height].to_f
      if w_original < w && h_original < h
        return image
      end
      # resize
      image.resize("#{w}x#{h}")
      image
    end
  end

  def set_content_image_type(*args)
    self.file.instance_variable_set(:@content_type, "image/png")
  end


  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    ActionController::Base.helpers.asset_path("assets/" + [version_name, "default.png"].compact.join('_'))
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

  protected
  def is_multi?(new_file)
    !model.multi_upload.nil? and !model.multi_upload
  end

  def image_rotation
    manipulate! do |image|
      image.rotate  model.rotate || 0
      image
    end
  end

end
