class OrganizationMembership
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :org_id, :type => String
  field :notification_id
  belongs_to :profile
  belongs_to :organization#,foreign_key: :org_id
  embeds_many :seasons , cascade_callbacks: true
  embeds_one :meta_data , class_name: "MetaData", inverse_of: :meta_data, cascade_callbacks: true

  has_many :notifications, class_name: "Notification", autosave: true, inverse_of: :organization_membership
  embeds_many :phone_numbers
  scope :active, where('seasons.status'=>'active')
  # index(es)
  index({ org_id: 1 }, { background: true })
  index "seasons.sessions.name" => 1
  index "seasons.org_season_id" => 1
  index "seasons.is_current" => 1
  index "seasons.sessions.name" => 1
  index "seasons.age_group_and_school_days" => 1
  index "meta_data.lname_downcase"=>1
  index "meta_data.nickname_downcase"=>1
  scope :active, where("seasons.status"=> "active" )

  #Callbacks ----------------------------
  after_create :add_meta_data

  # creates meta_data(fname,lname,birthdate etc from kids profiles)
  def add_meta_data
    kids_type = profile.kids_type
    create_meta_data(fname: kids_type.fname,fname_downcase: kids_type.fname.to_s.downcase,
                     lname: kids_type.lname,lname_downcase: kids_type.lname.to_s.downcase,
                     nickname: kids_type.nickname || kids_type.fname,nickname_downcase: kids_type.nickname.to_s.downcase || kids_type.fname.to_s.downcase,
                     birthdate: kids_type.birthdate )
  end

  def organization
    Organization.find(org_id)
  end

  #returns child applied_season based on organization_membership & season_year
  def applied_season(season_id)
    seasons.where(org_season_id: BSON::ObjectId.from_string(season_id)).first
  end



  def coll_hash(org_att)
    hash = {}; att = Array.new(); org_att.attributes.each { |k,v| hash[k] = v and att.push(k)  }
    return hash, att
  end

  def new_attr_hash(exit_att,org_att)
    kids_data , kids_att = coll_hash(org_att)
    kids_data.delete_if {|k, v|  exit_att.include? k }
  end

  def self.member(kids_id)
    orgnization_list = OrganizationMembership.where(:profile_kids_type_id => kids_id.to_s)
    org_season = []
    orgnization_list.each do |each_organization|
      @organization_details = Organization.where(:_id => each_organization.org_id).first
      each_organization.seasons.each do |each_season|
        org_season << @organization_details.name.to_s+','+each_season.org_season_id.to_s+','+each_season.application_form_status.to_s+','+each_organization.org_id.to_s+','+@organization_details.phone_no.to_s+','+@organization_details.fax_no.to_s+','+@organization_details.address1.to_s+','+@organization_details.email.to_s+','+each_season.membership_enrollment.active_member_of_ppc.to_s+','+each_season.membership_enrollment.age_group_and_school_days.to_s+ ','+each_season.membership_enrollment.family_currently_enrolled.to_s+','+@organization_details.networkId.to_s+','+@organization_details.preffered_name.to_s+','+@organization_details.address2.to_s+','+@organization_details.address3.to_s+','+@organization_details.logo.to_s+','+each_season.membership_enrollment.secondary_choice_of_class_days.to_s
      end
    end
    return org_season
  end

  class << self
    def find_by_org_and_kid(org_id, kid_id )
      #raise kid_id.id.inspect
      #raise kid_id.kids_type.id.inspect
      # ideally, result set should not contain more than 1 result
      # but, just grab top element
      kid_org_membership  = OrganizationMembership.where(:org_id => org_id, :profile_id => kid_id.id).first

      #try old way, just incase of nil returns
      kid_org_membership||= OrganizationMembership.where(:org_id => org_id, :profile_kids_type_id => kid_id.kids_type.id).first

      # return child org membership instance
      return kid_org_membership
    end


    def enrollees_aggregate(org_id,conditions,sort_by)
      OrganizationMembership.collection.aggregate({"$match"=>{org_id:  org_id }},{ "$unwind" => "$seasons" },
                                                  { "$project"=> { _id: 1,
                                                                   profile_id: 1,
                                                                   lname: "$meta_data.lname",
                                                                   fname: "$meta_data.fname",
                                                                   nickname:"$meta_data.nickname",
                                                                   birthdate: "$meta_data.birthdate",
                                                                   fname_downcase: "$meta_data.fname_downcase",
                                                                   lname_downcase: "$meta_data.lname_downcase",
                                                                   nickname_downcase: "$meta_data.nickname_downcase",
                                                                   org_season_id: "$seasons.org_season_id" ,
                                                                   season_status: "$seasons.status" ,
                                                                   age_group_and_school_days: "$seasons.age_group_and_school_days" ,
                                                                   application_date: '$seasons.created_at' ,
                                                                   application_status: '$seasons.application_status',
                                                                   alerts_outstanding: '$seasons.alerts_outstanding'}
                                                  },
                                                  {"$match"=>conditions},
                                                  {"$sort"=> sort_by})
    end


  end
  def safe_hash
    to_a.delete_if {|k, v|  ['_id','profile_id','created_at','updated_at','_type', 'email'].include? k }
  end
end
