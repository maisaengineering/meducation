class Notification
  include Mongoid::Document
  #include ActiveModel::AttributeMethods
  include ActiveModel::Translation
  extend ActiveModel::Naming
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  private_class_method :new

  #--------- Attributes & Variables
  NOTIFICATION_TYPES =  {alert: "Alert", event: "Event" }
  CATEGORIES =  {document: "Document", form: "Form" }

  #--------  Fields
  field :notification_type, default: NOTIFICATION_TYPES[:alert]

  field :user_id
  field :acknowledgment_date,type: Time
  field :submitted_count,type: Integer,default: 0
  field :status ,default: 'active'

  attr_accessor :data_clean_up

  #--------- Relations
  belongs_to :organization_membership, class_name: "OrganizationMembership", inverse_of: :notifications, index: true
  belongs_to :season, class_name: "Season", inverse_of: :notifications, index: true
  belongs_to :document ,index: true
  belongs_to :document_definition ,index: true
  belongs_to :json_template, index: true
  belongs_to :acknowledgment_by, foreign_key: "user_id", class_name: "User" ,index: true
  belongs_to :ae_definition,index: true ,counter_cache: true
  belongs_to :profile ,index: true

  #Scopes ------------------
  #default_scope desc(:updated_at)
  #default_scope desc(:created_at) # get recently created first
  scope :requested ,where(is_accepted: 'requested')
  scope :submitted ,where(:is_accepted.ne=> 'requested') #or use excludes #except requested (i.e; ApplicationForm rejected,submitted,withdrawn etc..)
  scope :ive_done_it ,where(is_accepted: AeDefinition::REQUEST_BUTTONS[:ive_done_it]) # to count user activity notifications response
  scope :ignored ,where(is_accepted: AeDefinition::REQUEST_BUTTONS[:ignore])
  scope :thanks ,where(is_accepted: AeDefinition::REQUEST_BUTTONS[:thanks])
  scope :remind_me_later, where(is_accepted: AeDefinition::REQUEST_BUTTONS[:remind_me_later])
  #returns only alerts
  scope :alerts ,where(notification_type: NOTIFICATION_TYPES[:alert])
  scope :documents ,where(category: CATEGORIES[:document])
  scope :forms ,where(category: CATEGORIES[:form])
  scope :org_wide,where(:season_id.exists => false)
  # unexpired(valid) + rest(ex: expiring_on not exists for forms/docs so we need include those also)
  scope :unexpired ,any_of({:expiring_on.gte=> Date.today}, {:expiring_on.exists=> false})
  scope :expired ,where(:expiring_on.lt => Date.today)
  scope :recent,  limit(3).desc(:created_at)
  scope :by_acceptance, ->(accpt){ where(:is_accepted => accpt) }
  scope :only_memberships, only(:organization_membership)

  scope :normal, where(_type: "NormalNotification")
  scope :ad_hoc, where(_type: "AdHocNotification")
  scope :scheduled, where(_type: "ScheduleNotification")



  # Index(es)- for relations just add index: true ex: belongs_to :profile,index: true will automatically adds the Fk index
  index({ notification_type: 1 }, { background: true })
  index({ season_field: 1})
  index "is_accepted" => 1


  #--------- Validations goes here

  #--------  Callbacks goes here
  after_update :remind_alert, if: proc{|noti| noti.is_accepted_changed? and noti.is_accepted.eql?(AeDefinition::REQUEST_BUTTONS[:remind_me_later])}

  #---------  Class Methods goes here

  #---------- Instance Methods
  def season
    season_id.nil? ? nil : organization_membership.seasons.find(season_id)
  end

  def organization
    organization_membership.organization
  end
  # case 1: notification created_at + ae_definition.due_by_days
  # case 2: case1 is wrong if a kid registered and theirs age between the occurring days and due by days
  # EX case1: occurring_days = 365(kid age in days) and due_by_days = 10 => created_at + 10 => 10 days from notification created
  # Ex case2: below

  def due_by
    #occurring_days = ae_definition.occurring_days
    dob = profile.kids_type.birthdate.to_date
    dob  + (ae_definition.occurring_days + ae_definition.due_by_days )
  end

  def issued_on
    dob = profile.kids_type.birthdate.to_date
    dob  + (ae_definition.occurring_days)
  end

  def alert?
    notification_type.eql?(NOTIFICATION_TYPES[:alert])
  end


  def belongs_to_season?(org_season_id)
    self.organization_membership.seasons.where(id: self.season_id).first.org_season_id.eql?(org_season_id)
  end

  def parent
    @parent ||= Profile.find(self["parent_id"].to_s)
  end

  private

  def remind_alert
    Delayed::Job.enqueue RemindAlert.new(self.id ), :run_at=>7.days.from_now
  end

  def send_alert_email
    unless data_clean_up
      sender = profile.parent_type ? profile : parent
      if sender and !sender.parent_type.ae_notification_opt_out
        Notifier.delay.ae_alerts(self, sender.parent_type.email)
      end
    end
  end
end
