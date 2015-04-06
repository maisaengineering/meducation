#-----------------------------------------------------------------------------------------------------------------------
# AlertOrEventDefinition is defined by super admin or hospital admin.This model is of Two types
#  i)AdHocDefinition ii)ScheduleDefinition
# reference of this id will be saved in Notification(belongs_to this).We can classify(user notifications) ...
# the alerts and events is of AdHoc Or Scheduled
#++ --------------------------------------------------------------------------------------------------------------------
class AeDefinition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  #private_class_method :new

  #Attributes & Variables -----------------
  DEFINITION_TYPES =  {alert: 'Alert', event: 'Event' }
  REQUEST_BUTTONS =  {ive_done_it: "I've done it",thanks: 'Thanks', ignore: 'Ignore', remind_me_later: "Remind me later" }
  EXPECTED_RESPONSE = {REQUEST_BUTTONS[:ive_done_it]=> REQUEST_BUTTONS[:ive_done_it],REQUEST_BUTTONS[:thanks]=> REQUEST_BUTTONS[:thanks], REQUEST_BUTTONS[:ignore]=> REQUEST_BUTTONS[:ignore], "Snooze"=>  REQUEST_BUTTONS[:remind_me_later], REQUEST_BUTTONS[:remind_me_later] => "Snooze"}
  STATUS=  {"Active"=>"active", "Inactive"=> "inactive"}
  attr_accessor :occurring_days,:due_by_days#,:occurring_on
  #Fields ---------------------------------
  field :definition_type
  field :title
  field :sub_line
  field :category
  field :content
  field :request_buttons ,type: Array
  #field :age_range,type: Range
  field :status ,default: 'active'
  #field :zip_codes, type: Array
  field :notifications_count, type: Integer, default: 0
  field :to_whom ,default: 'kid'

  #Relations ------------------------------
  #belongs_to :hospital,index: true
  has_many :notifications ,dependent: :destroy

  #Scopes ---------------------------------
  scope :active ,where(status: 'active')
  scope :inactive ,where(status: 'inactive')
  scope :alerts ,where(definition_type: DEFINITION_TYPES[:alert])
  scope :events ,where(definition_type: DEFINITION_TYPES[:event])
  scope :ad_hoc,where(_type: "AdHocAeDefinition")
  scope :scheduled,where(_type: "ScheduledAeDefinition")

  #Index(es) ------------------------------

  #Validations goes here-------------------
  #validates :hospital_id ,:title,:definition_type,:request_buttons,:to_whom,presence: true

  #Callbacks goes here --------------------
  #before_save :set_age_range

  #Class Methods goes here-----------------

  #Instance Methods -----------------------

  #def set_age_range
  #  self.age_range = min_age_range..max_age_range
  #  self.zip_codes = zip_codes.split(',').flatten
  #end

  # checks if its ad_hoc or scheduled
  def ad_hoc?
    _type.eql?(AdHocAeDefinition.to_s)
  end

  def scheduled?
    _type.eql?(ScheduledAeDefinition.to_s)
  end

  def expected_responses
    request_buttons.collect do |key|
      EXPECTED_RESPONSE[key]
    end
  end

end
