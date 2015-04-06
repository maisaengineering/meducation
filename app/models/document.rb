#--
# User(parent) will upload the documents
# Documents are universal,
# Tags : ----
# rest of the comments goes here ...
# References : https://github.com/jnicklas/carrierwave-mongoid
#              https://github.com/wilkerlucio/mongoid_taggable

#++
class Document
  include Mongoid::Document
  include Mongoid::Timestamps
  #TAG
  include Mongoid::Taggable
  include Mongoid::Attributes::Dynamic

  #--------  Fields
  field :profile_id
  field :names,type: Array
  field :document_type
  field :org_provider
  field :description
  field :taken_on, type:Date, default: Date.today
  field :expiration_date, type:Date, default:nil
  field :multi_upload, type: Mongoid::Boolean, default: false
  #field :category_id
  field :attachment_processing ,type: Mongoid::Boolean ,default: false
  field :source

  field :attachment
  #--------- Attributes & Variables
  attr_accessor :tag_name, :rotate, :canvas_url,:exif_data

  PHOTOGRAPH = 'Identity Photo'
  QUICKCAPTURE = 'Quick captures'
  #--------- Relations
  # for Photograph use old source uploader(grid_fs)
  mount_uploader :source, SourceUploader ,dependent: :destroy # source
  mount_uploader :attachment, DocumentUploader ,dependent: :destroy # source

  belongs_to :profile ,foreign_key: :profile_id
  belongs_to :category
  has_many :notifications

  # Saves image exif data after strip
  has_one :multi_media_meta_data, as: :target, dependent: :destroy

  #--------- Scopes
  default_scope desc(:created_at)
  scope :recent, limit(5).desc(:created_at)
  #this scope returns all the documents uploaded by related parents them self not for kids
  scope :family, ->(profile_ids){ where(:profile_id.in=>profile_ids)}
  scope :single, where(multi_upload: false) # a document with single capture
  scope :multiple, where(multi_upload: true) #a document from multiple captures(form multiple documents)


  #--------- Validations
  validates :profile_id, presence: true
  validates :attachment, presence: true , file_size: {maximum: 20.megabytes.to_i}, unless: Proc.new { |doc| doc.category.name.eql?(Document::PHOTOGRAPH) || doc.tags.include?(Document::PHOTOGRAPH) || doc.respond_to?(:doc_ids)}
  validates :source, presence: true , file_size: {maximum: 20.megabytes.to_i}, if: Proc.new { |doc| doc.category.name.eql?(Document::PHOTOGRAPH)  || doc.tags.include?(Document::PHOTOGRAPH) }

  #--------  Callbacks
  #before_save :add_recently_shared_name
  before_save :assign_tags
  before_validation :assign_source_from_canvas_url, if: Proc.new{|doc|  doc.source.blank? and !doc.canvas_url.blank? }
  after_create :create_photograph_versions, if: Proc.new { |doc| (doc.category and doc.category.name.eql?(Document::PHOTOGRAPH)) || doc.tags.include?(Document::PHOTOGRAPH) }
  before_create :set_photograph_under_process , if: Proc.new { |doc| (doc.category and doc.category.name.eql?(Document::PHOTOGRAPH)) || doc.tags.include?(Document::PHOTOGRAPH) }
  before_update :store_initial_profile_id
  after_save :add_photograph_url_meta_data, if: Proc.new { |doc| (doc.category and doc.category.name.eql?(Document::PHOTOGRAPH)) || doc.tags.include?(Document::PHOTOGRAPH) }
  after_destroy :remove_photograph_url_meta_data, if: Proc.new { |doc| (doc.category and doc.category.name.eql?(Document::PHOTOGRAPH)) || doc.tags.include?(Document::PHOTOGRAPH) }
  after_save :schedule_expire_notification, if: Proc.new{|doc| !doc.multi_upload and doc.expiration_date and doc.attachment.file}
  before_destroy :remove_expire_notification, if: Proc.new{|doc| !doc.multi_upload and doc.expiration_date}
  # Save Exif data into separate collection if exists
  after_save do |record|
    record.create_multi_media_meta_data(exif: record.exif_data) if not record.exif_data.blank?
  end

  #Find category and its ancestors then assign to tags before_crating the record
  # NOTE : when ever we change assin_tags, we would mind to keep the order of tags as [root, child, leaf] (or) [root, usertag1, usertag2]
  def assign_tags
    category_tags = ""
    if category
      category_tags =(category.ancestors.asc(:created_at).map(&:name).push(category.name)).uniq.join(',')
    end
    self.tags  = ( category_tags + ','+self.tags).split(',').uniq.join(',')  #if assigns the tags from form or explicitly
  end

  def create_photograph_versions
    self.set(:multi_upload => false) unless self.multi_upload == false
    self.delay(queue: 'photograph_versions').recreate_photograph_versions!
  end


  def set_photograph_under_process
    self.attachment_processing = true
  end

  #def add_recently_shared_name
  #  self.names ||= []
  #  self.names.push(recent_name) if recent_name.present?
  #  self.names = self.names.uniq
  #end


  def recreate_delayed_versions!
    self.attachment.cache_stored_file!
    self.attachment.recreate_versions!
    # self.attachment.preload_image_to_cdn('converted_pdf')
    self.update_attributes(attachment_processing: false)
  end

  def recreate_photograph_versions!
    self.source.cache_stored_file!
    self.source.recreate_versions!
    self.update_attributes(attachment_processing:false)
    # self.add_photograph_url_meta_data
  end

  #self.names consists list of names of the document_definition when it shared.
  #so the name of the document should be recently shared with an org document_definition (i,e last element)
  def name
    tags_array.last
  end

  def photo_graph?
    tags_array.include?(Document::PHOTOGRAPH)
  end

  #to get original filename of source
  def original_filename
    File.basename(attachment.path)
  end

  #The identification of MIME content type is based on a file‘s filename extensions.
  #OP explicitly requested a method based on content analysis, not filename extension
  def extension_is?(type)
    #get file extension of source uploader
    mtype = MIME::Types[attachment.file.content_type].first
    mtype.registered? ?  mtype.extensions.first.to_sym.eql?(type) : mtype.sub_type.to_sym.eql?(type)
  end

  # returns documents_definitions shared by this document org wide season wide
  def shared_with
    document_definition_ids = notifications.only(:document_definition_id).map(&:document_definition_id)
    DocumentDefinition.where(:_id.in=>document_definition_ids)
  end

  #======================= text to show dashboards====
  def display_name
    self.tags_array.last || self.names.first
  end

  def profile_name
    self.profile.nickname if self.profile
  end

  def category_name
    (self.tags_array & Category.roots.map(&:name)).join
  end

  def edit_taken_on=(val)
    self.taken_on =val
  end

  def edit_expire_on=(val)
    self.expiration_date =val
  end

  def assign_source_from_canvas_url
    imagedata = self.canvas_url.split(',').last
    io = FilelessIO.new(Base64.decode64(imagedata))
    io.original_filename = "#{self.id}.png"
    self.source= io
  end

  def file=(params)
    if params.include?(:content) and params.include?(:name) and params.include?(:content_type)
      imagedata = params[:content].split(',').last
      io = FilelessIO.new(Base64.decode64(imagedata))
      io.original_filename = params[:name]
      io.content_type = !MIME::Types[params[:content_type]].blank? ? params[:content_type] : "application/octet-stream"
      unless category.name.eql?(Document::PHOTOGRAPH)
        self.attachment= io
      else
        self.multi_upload = true
        self.source= io

      end
    end
  end

  def photo=(params)
    if params.include?(:content)
      imagedata = params[:content].split(',').last
      io = FilelessIO.new(Base64.decode64(imagedata))
      io.original_filename = params[:name] || "#{self.id}.jpeg"
      io.content_type = !MIME::Types[params[:content_type]].blank? ? params[:content_type] : "application/octet-stream"
      self.multi_upload = true
      self.attachment= io
    end
  end

  def self.pdf_conversion_cmd(files,bw=false)
    bw = bw ? '-monochrome' : nil
    # /usr/local/bin/convert
    "convert #{files} #{bw} -auto-orient -despeckle -auto-level -level 10%,90% -contrast -fuzz 35% -trim +repage -sharpen 0x1 -resize @30000000 -units PixelsPerInch -density 600x600 -quality 40"
  end

  # def delete_phatograph_cache
  #   Rails.cache.delete("#{self.profile_id}_photo")
  # end

  def store_initial_profile_id
    if !new_record? and profile_id_changed? and !respond_to?(:initial_profile_id)
     self[:initial_profile_id]= profile_id_was
    end
  end

  def add_photograph_url_meta_data
    meta_data = profile.meta_data
    meta_data = profile.build_meta_data() unless meta_data
    meta_data[:thumb_photo_url] = (source.thumb.file_exists? ? source.thumb.url: "")
    meta_data[:photo_url] = source.url
    meta_data.save
  end

  def remove_photograph_url_meta_data
    profile.unset(:meta_data) if profile.meta_data
    profile.aggregate_photograph_url
  end

  #DERBE: Document Expire Notification showing Before 30 day.
  #DERON: Document Expire Notification showing ON same day.

  def schedule_expire_notification
    remove_expire_notification
    self.delay(queue: "DERBE#{kl_id.gsub('-','')}", run_at: analyze_date).create_expire_notification
  end

  def remove_expire_notification
    Delayed::Job.in(queue: ["DERBE#{kl_id.gsub('-','')}", "DERON#{kl_id.gsub('-','')}"]).destroy
    DocumentExpirationNotification.where(document_id: id).destroy
  end

  def create_expire_notification
    notification = DocumentExpirationNotification.find_or_initialize_by(document_id: id, profile_id:profile_id)
    notification.save
  end

  def analyze_date
    adate= expiration_date-30.days
    adate>Date.today ? adate : Date.today
  end
end



