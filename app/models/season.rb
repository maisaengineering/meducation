class Season
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic


  embedded_in :organization_membership
  embedded_in :organization
  embeds_many :sessions
  embeds_one :membership_enrollment
  # embeds_many :organization_forms
  has_many :json_templates
  #embeds_many :organization_documents
  #has_many :season_attachments
  has_many :document_definitions   #, cascade_callbacks: true
  has_many :notifications, class_name: "Notification", autosave: true, inverse_of: :season
  embeds_many :phone_numbers

  field :season_year , :type => String
  field :season_fee, :type => Float, :default => 0.0
  #field :is_accepted, :type => String, :default => 'Application submitted'
  field :is_current, :type => Integer, :default => 0
  field :status, :type => String, :default => "inactive"
  field :terms, :type => Mongoid::Boolean
  field :org_season_id
  #accepts_nested_attributes_for :sessions , reject_if: :all_blank, :allow_destroy => true, autosave: true
  accepts_nested_attributes_for :sessions, allow_destroy: true, :reject_if => proc { |attributes| attributes['session_name'].blank? }
  #TODO add unique validation for season_year

  validates :season_year,presence: true , :unless=> Proc.new { |s| s.organization.nil?}

  scope :active ,where(status: 'active')
  scope :inactive ,where(status: 'inactive')

  #callbacks
  before_save :remove_current,:unless=> Proc.new { |s| s.organization.nil?}
  before_create {self[:application_status] = 'Application submitted' if not self.organization_membership.nil?}
  # After upgrading to Rails4/Mongoid4 ,adding new session to season from org update not working
  # reassign sessions before updating will fix the problem
  before_update :reassign_sessions

  def reassign_sessions
    self.sessions = sessions
  end

  def remove_current
    season_year.slice! '(current)' #remove current if includes
    season_year.strip! #remove spaces
  end

  def current_season_year
    is_current.eql?(0) ? season_year : "#{season_year} (current)"
  end

  class << self
    def find_kid_applied_seasons(kid_id, org_id, org_season_id)
      kid_applied_seasons = Array.new
      kid_org_membership = OrganizationMembership.find_by_org_and_kid(org_id, kid_id)
      if kid_org_membership
        kid_org_membership.seasons.each { |kid_org_membership_season|
          if org_season_id.to_s == kid_org_membership_season.org_season_id.to_s
            kid_applied_seasons.push(kid_org_membership_season)
          end
        }
      end

      return kid_applied_seasons
    end
  end

  def coll_hash
    hash = {}; att = Array.new(); self.attributes.each { |k,v| hash[k] = v and att.push(k)  }
    return hash, att
  end

  def new_attr_hash(exit_att)
    kids_data , kids_att = coll_hash
    kids_data.delete_if {|k, v|  exit_att.include? k }
  end

  #returns application form
  def application_form
    #json_template = Organization.find(organization_membership.org_id).json_templates.detect { |aTemplate|
    #  aTemplate.workflow ==  JsonTemplate::WORKFLOW_TYPES[:appl_form] && aTemplate.season.season_year ==  season_year
    #}
    begin
      organization = Organization.find(organization_membership.org_id)
      org_season = organization.seasons.find(org_season_id)
      json_template = organization.json_templates.where(workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form],season_id: org_season.id).first
      notifications.where(json_template_id: json_template.id).first
    rescue
    end


  end
  #returns application form status for this season
  def application_form_status
    application_form.is_accepted rescue nil

  end


  def safe_attr_hash
    to_a.delete_if {|k, v| ['_id', '_type', 'created_at', 'updated_at','terms', 'updated_at','is_current','id'].include? k }
  end

  def org_season_year
    organization_membership.organization.seasons.find_by(_id:org_season_id).season_year
  end
end
