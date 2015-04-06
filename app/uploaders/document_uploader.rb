# encoding: utf-8
require 'carrierwave/processing/mini_magick'
require 'carrierwave/processing/mime_types'
class DocumentUploader < CarrierWave::Uploader::Base
  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  #include Sprockets::Helpers::RailsHelper
  #include Sprockets::Helpers::IsolatedHelper
  include CarrierWave::MimeTypes
  #update original filename with timestamp with picoseconds
  include Mschool::CarrierWave::StripExifData
  include Mschool::CarrierWave::ChangeFilename
  include Mschool::CarrierWave::CdnVersions

  storage :fog

  # process cropping: [575,820], if: :image?
  process :strip
  process :tapping, if: :image?
  process :resize_3000, if: :image?
  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  # def store_dir
  #  "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  # end

  def store_dir
    if model.respond_to?(:initial_profile_id)
      "#{model.class.to_s.underscore}/#{mounted_as}/#{model.initial_profile_id}/#{model.id}"
    elsif model.profile_id_changed? and !model.profile_id_was.blank?
      "#{model.class.to_s.underscore}/#{mounted_as}/#{model.profile_id_was}/#{model.id}"
    elsif model.profile_id
      "#{model.class.to_s.underscore}/#{mounted_as}/#{model.profile_id}/#{model.id}"
    else
      "#{model.class.to_s.underscore}/#{mounted_as}/m-upload/#{model.id}"
    end
  end

  def fog_directory
    'test-kl-tmp'
  end


  version :thumb ,if: :image_or_pdf_not_multi? do
    process cropping: [115,168]
    #convert to png if its a pdf ,to generate thumb for first page
    process convert: 'png'
    process :set_content_image_type
    def full_filename (for_file = model.source.file)
      super.chomp(File.extname(super)) + '.png'
    end
  end


  #version :bw_pdf ,if: :pdf_and_not_multi?  do
  #  process :convert_pdf_from_color_to_bw
  #  #process :delete_unwanted_document
  #end

  # create from b/w png
  #version :converted_bw_pdf , if: :image_and_not_multi? do
  #  process :convert_to_bw_pdf
  #  #process :bw_pdf_format
  #  process :set_content_type
  #  def full_filename (for_file = model.source.file)
  #    super.chomp(File.extname(super)) + '.pdf'
  #  end
  #end

  version :converted_pdf, if: :image_and_not_multi? do
    # process :color_pdf_format
    process :convert_to_color_pdf
    process :set_content_type
    def full_filename (for_file = model.source.file)
      super.chomp(File.extname(super)) + '.pdf'
    end
  end

  def set_content_type(*args)
    self.file.instance_variable_set(:@content_type, "application/pdf")
  end

  def set_content_image_type(*args)
    self.file.instance_variable_set(:@content_type, "image/png")
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    asset_path("fallback/" + [version_name, "default-photo.png"].compact.join('_'))
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png pdf)
  end

  #def md5
  #  begin
  #    chunk = model.send(mounted_as)
  #    @md5 ||= Digest::MD5.hexdigest(chunk.read)
  #  rescue
  #    original_filename
  #  end
  #end
  #
  #def filename
  #  @name ||= "#{md5}#{File.extname(super)}" if super
  #end

  protected
  def image_or_pdf?(new_file)
    new_file.content_type.include?('image') || new_file.content_type.include?('pdf')
  end

  def pdf?(new_file)
    new_file.content_type.include? 'pdf'
  end

  def image?(new_file)
    new_file.content_type.include? 'image'
  end

  def pdf_and_not_multi?(new_file)
    pdf?(new_file) and model.multi_upload==false
  end

  def image_and_not_multi?(new_file)
    image?(new_file) and model.multi_upload==false
  end

  def image_or_pdf_not_multi?(new_file)
    image_or_pdf?(new_file) and model.multi_upload == false
  end

  def multi?(new_file)
    image?(new_file) and model.multi_upload
  end

  def cropping(w,h)
    manipulate! do |image|
      image.tap(&:auto_orient)
      w_original = image[:width].to_f
      h_original = image[:height].to_f
      if w_original < w && h_original < h
        return image
      end
      # resize
      image.density(300)
      image.resize("#{w}x#{h}")
      image
    end
  end

  def tapping
    manipulate! do |image|
      image.tap(&:auto_orient)
      image
    end
  end

  #def convert_pdf_from_color_to_bw
  #  manipulate! do |image|
  #    temp_path = "#{Rails.root.join('tmp')}/uploader-documents/bw/#{model.id}-#{Time.now.strftime("%Y%m%d%H%M%S%L-%12N")}"
  #    FileUtils::mkdir_p temp_path
  #    if model.respond_to?(:doc_ids) and !model.doc_ids.blank? # combination of multiple images
  #      doc_urls = []
  #      Document.in(id: model.doc_ids).asc(:created_at).each_with_index do |document|
  #        unless document.extension_is?(:pdf)
  #          doc_urls << document.attachment.url
  #        end
  #      end
  #      # convert all into single pdf
  #      system <<-COMMAND
  #        #{Document.pdf_conversion_cmd(doc_urls.join(' '),true)} #{temp_path}/bw.pdf
  #      COMMAND
  #      image = MiniMagick::Image.open("#{temp_path}/bw.pdf")
  #      FileUtils.rm_rf(Dir["#{temp_path}"]) # remove directory from tmp
  #    else  #uploaded pdf it self
  #      # For Good Quality B/W use below
  #      #system <<-COMMAND
  #      #  convert -density 300 #{model.attachment.url} -threshold 50% -type bilevel -compress fax #{temp_path}/#{model.id}#{File.extname(model.attachment.url)}
  #      #COMMAND
  #      #image = MiniMagick::Image.open("#{temp_path}/bw.pdf")
  #      # convert #{@document.attachment.url}  -monochrome -format pdf -density 300 #{temp_path}/#{random_string}.pdf
  #      image.monochrome
  #      image.format("pdf")
  #    end
  #    image
  #  end
  #end

  #def remove_color
  #  manipulate! do |img|
  #    #img.threshold('40%')
  #    img.monochrome
  #    img
  #  end
  #end

  def resize_3000
    manipulate! do |img|
      img.resize('3000>')
      img
    end
  end

  def convert_to_bw_pdf
    manipulate! do |img|
      temp_path = "#{Rails.root.join('tmp')}/uploader-documents/bw/#{model.id}-#{Time.now.strftime("%Y%m%d%H%M%S%L-%12N")}"
      FileUtils::mkdir_p temp_path
      system <<-COMMAND
         #{Document.pdf_conversion_cmd(img.path,true)} #{temp_path}/bw.pdf
      COMMAND
      img = MiniMagick::Image.open("#{temp_path}/bw.pdf")
      FileUtils.rm_rf(Dir["#{temp_path}"]) # remove directory from tmp
      img
    end
  end

  def convert_to_color_pdf
    manipulate! do |img|
      temp_path = "#{Rails.root.join('tmp')}/uploader-documents/color/#{model.id}-#{Time.now.strftime("%Y%m%d%H%M%S%L-%12N")}"
      FileUtils::mkdir_p temp_path
      system <<-COMMAND
         #{Document.pdf_conversion_cmd(img.path)} #{temp_path}/color.pdf
      COMMAND
      img = MiniMagick::Image.open("#{temp_path}/color.pdf")
      FileUtils.rm_rf(Dir["#{temp_path}"]) # remove directory from tmp
      img
    end
  end

  #def bw_pdf_format
  #  manipulate! do |img|
  #    img.format("pdf") do |c|
  #      c.monochrome
  #
  #    end
  #    img
  #  end
  #end

  #def color_pdf_format
  #  manipulate! do |img|
  #    img.format("pdf") do |c|
  #      c.density(300)
  #    end
  #    img
  #  end
  #end

  #def convert_to_pdf
  #  cached_stored_file! if !cached?
  #  pdf = Prawn::Document.new(page_layout: :portrait,page_size: 'A4',
  #                            left_margin: 10,right_margin: 10,top_margin: 10,
  #                            bottom_margin: 10, background_scale: 300)
  #  #pdf.image(current_path)
  #  pdf.image current_path ,position: :center
  #  dirname = File.dirname(current_path)
  #  thumb_path = "#{File.join(dirname, File.basename(path, File.extname(path)))}.pdf"
  #  pdf.render_file(thumb_path)
  #  File.rename thumb_path, current_path
  #end

end