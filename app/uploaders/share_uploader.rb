# encoding: utf-8
require 'carrierwave/processing/mini_magick'
class ShareUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  #update original filename with timestamp with picoseconds
  include Mschool::CarrierWave::StripExifData
  include Mschool::CarrierWave::ChangeFilename
  include Mschool::CarrierWave::CdnVersions

  # Choose what kind of storage to use for this uploader:
  #storage :file

  storage :fog
  process :strip
  process :image_rotation ,if: :milestone_image?
  process resize_to_fill: [343, 244],if: :snapshot?

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "shares/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # If Logo is for Organization use organization bucket else Hospital Bucket ...
  def fog_directory
    'test-kl-tmp'
    #Rails.env.production? ? 'ms-templates' : 'test-ms-templates'
  end



  # def asset_host
  #   ENV['CDN_URL']
  # end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:

  version :mobile ,if: :can_create_version? do
    process :resize_to_fit => [640, 480]
    process convert: 'jpeg'
    process :set_content_image_type
    def full_filename (for_file = model.source.file)
      super.chomp(File.extname(super)) + '.jpeg'
    end
  end

  def set_content_image_type(*args)
    self.file.instance_variable_set(:@content_type, "image/jpeg")
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  def not_snapshot_image?(new_file)
    !mounted_as.eql?(:snapshot)
  end

  def can_create_version?(new_file)
    (!mounted_as.eql?(:snapshot) and model.enable_versions)
    # !mounted_as.eql?(:snapshot)
  end

  private
  def image_rotation
    manipulate! do |image|
      image.rotate  model.rotate || 0
      image
    end
  end

  def snapshot?(new_file)
    mounted_as.eql?(:snapshot)
  end

  def milestone_image?(new_file)
    mounted_as.eql?(:milestone_image)
  end

  def apply_300_dpi
    manipulate! do |img|
      img.density(300)
      img
    end
  end


  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
