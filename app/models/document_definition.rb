class DocumentDefinition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  #--------- Attributes & Variables
  TYPE = {organization_wide: 'Organization-wide'}
  WORKFLOW_TYPES =  {normal: "Normal", auto: "Auto at acceptance" }
  PHOTOGRAPH =  'Photograph of child'
  #--------  Fields
  field :organization_id
  field :season_id
  field :name
  field :workflow ,default: WORKFLOW_TYPES[:normal]
  field :is_for_season ,type: Mongoid::Boolean,default: false
  #field :is_hidden ,type: Boolean,default: false
  #add indexes for relation we can give directly via index option
  index({season_id: 1})

  #--------- Relations
  belongs_to :organization ,foreign_key: :organization_id ,index: true
  belongs_to :season ,foreign_key: :season_id
  has_many :notifications
  #--------- Scopes
  default_scope desc(:created_at) #recent first
  #to get all organization wide definitions
  scope :org_wide ,where(is_for_season: false)
  scope :normal ,where(workflow: WORKFLOW_TYPES[:normal])
  scope :auto ,where(workflow: WORKFLOW_TYPES[:auto])
  #scope :hidden ,where(is_hidden: true)
  #scope :non_hidden ,where(is_hidden: false)



  #--------- Validations
  validates :organization_id,:name,:workflow,presence: true

  #--------  Callbacks
  before_save { |record| record.is_for_season = true if self.season_id.present?}
  before_save do |record|
    if self.season_id.present?
      record.season_id = BSON::ObjectId.from_string(self.season_id)
    else
      record.unset(:season_id)
    end
  end
  #---------  Class Methods

  #---------- Instance Methods
  # season is embedded in organization so get the season through organization
  def season
    organization.seasons.find(season_id) unless season_id.blank?
  end

  #returns all the organization_memberships where this document_definition requested(default is requested i.e; document_definition_id is exists in)
  def organization_memberships
    if is_for_season?
      season_ids =  notifications.map(&:season_id)
      organization.organization_memberships.where(:"seasons._id".in => season_ids)
    else
      organization_membership_ids = notifications.map(&:organization_membership_id)
      organization.organization_memberships.where(:_id.in => organization_membership_ids)
    end
  end

  def organization_memberships_submitted
    if is_for_season?
      season_ids =  notifications.submitted.map(&:season_id)
      organization.organization_memberships.where(:"seasons._id".in => season_ids)
    else
      organization_ids = notifications.submitted.map(&:organization_membership_id)
      organization.organization_memberships.where(:_id.in => organization_ids)
    end
  end


  #returns th total number of requested count for this,i.e document_definition_id exists count in notifications
  def requested_count
    organization_memberships.count
  end
  #returns th total number of submitted count for this template
  def submitted_count
    organization_memberships_submitted.count
  end

  #returns documents of the user  who submitted/responded to this document_definition with document_id
  def submitted_documents
    document_ids =  notifications.submitted.map(&:document_id)
    Document.includes(:profile).where(:_id.in=>document_ids)
  end

  #creates a temp zip file and adds the content of documents
  def download_submitted_documents
    require 'zip/zip'
    file_name = name + Time.now.strftime("%m-%d-%Y %H:%M:%S:%3N")#with fraction of millisecond (3 digits)
    tempfile = Tempfile.new(file_name)
    Zip::ZipOutputStream.open(tempfile.path) do |z| # Give the path of the temp file to the zip outputstream, it won't try to open it as an archive.
      submitted_documents.each do |document|
        if document.photo_graph?
          doc_url = document.source.url
          doc_name = document.source.file.filename
        else
          doc_url =  document.extension_is?(:pdf) ? document.attachment.url : document.attachment.converted_pdf.url
          doc_name = document.extension_is?(:pdf) ?document.attachment.file.filename : document.attachment.converted_pdf.file.filename
        end
        z.put_next_entry(doc_name)
        z.print(URI.parse(doc_url).read)
      end
    end
    return tempfile,file_name
  end

end
