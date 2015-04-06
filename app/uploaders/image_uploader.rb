# encoding: utf-8
require 'carrierwave/processing/mini_magick'
class ImageUploader < CarrierWave::Uploader::Base

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
  # process resize only for milestone_image ,may user uploads large size images
  process :resize_3000,if: :milestone_image?

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "assets/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # If Logo is for Organization use organization bucket else Hospital Bucket ...
  def fog_directory
    # case model
    #   when Organization
    #     'test-organization-assets'
    #     #Rails.env.production? ? 'organization-assets' : 'test-organization-assets'
    #   when Hospital
    #     'test-hospital-assets'
    #     #Rails.env.production? ? 'hospital-assets' : 'test-hospital-assets'
    #   when TemplateImage
    #     'test-ms-templates'
    #     #Rails.env.production? ? 'ms-templates' : 'test-ms-templates'
    #   #when  Milestone#user uploaded photo from milestone creation page
    #   #  Rails.env.production? ? 'ms-templates/shares' : 'test-ms-templates/shares'
    #   #when --  if any
    # end
    'test-kl-tmp'
  end

  def asset_host
    if model.is_a?(TemplateImage)
      ENV['CDN_URL']
    end
  end

  def extension_white_list
    %w(jpg jpeg gif png)
  end

  protected

  def milestone_image?(new_file)
    mounted_as.eql?(:milestone_image)
  end

  def resize_3000
    manipulate! do |img|
      img.resize('3000>')
      img
    end
  end


end
