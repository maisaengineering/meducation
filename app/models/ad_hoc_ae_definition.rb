class AdHocAeDefinition < AeDefinition
  include Mongoid::Attributes::Dynamic
  public_class_method :new
  #Attributes & Variables -----------------

  #Fields ---------------------------------
  #field :occurring_on,type: Date


  #Relations ------------------------------

  #Scopes ---------------------------------

  #Index(es) ------------------------------

  #Validations goes here ------------------
  #validates :occurring_on,presence: true
  #Callbacks goes here --------------------
  #after_create :create_notifications, if: Proc.new{|adhoc| adhoc.status.eql?("active")}

  # create notifications immediately
=begin
  def create_notifications
    #---

    profile_ids = hospital.hospital_memberships.map(&:profile_id).uniq.compact

    if to_whom.eql?('parent')
      profile_ids.each do |profile_id|
        AdHocNotification.create!(is_accepted: 'requested',notification_type: definition_type,
                                  ae_definition_id: id,profile_id: profile_id).unset(:category)
      end
    else
      kids_ids = Profile.in(id: profile_ids).map(&:created_kids_ids).flatten.uniq.compact
      parents= Hash[Profile.collection.aggregate({"$unwind"=>"$parent_type.profiles_manageds"},
                                                 {"$match"=>{"parent_type.profiles_manageds.kids_profile_id"=>{"$in"=>kids_ids},
                                                             "parent_type.profiles_manageds.manageable"=>true}},
                                                 {"$group"=>{_id:"$parent_type.profiles_manageds.kids_profile_id", parent_ids:{"$push"=> "$_id"} }}).map(&:values)]

      kids_ids.each do |kid_id|
        parents[kid_id ].each do |parent_id|
          AdHocNotification.create!(is_accepted: 'requested',notification_type: definition_type,
                                    ae_definition_id: id,profile_id: kid_id, parent_id: parent_id).unset(:category)

        end
      end
    end


  end
=end

  #Class Methods goes here-----------------

  #Instance Methods -----------------------
end
