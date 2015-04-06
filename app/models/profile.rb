class Profile
  include Mongoid::Document
  include ActiveModel::AttributeMethods
  include ActiveModel::Translation
  extend ActiveModel::Naming
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid
  include Mongoid::Attributes::Dynamic
  include Mschool::Models::PhoneNumbers
  include Mschool::FieldChanges

   ####--------  Fields
   field :zipcode
   field :geo, type: Array

  field :docs_shared_to ,type: Array,default: []
  #geocoded_by :zipcode, coordinates: :geo


  ####--------- Attributes & Variables
  RELATION = ['Father', 'Mother']
  DOB_REGX = /^([1-9]|0[1-9]|1[012])[\/]([1-9]|0[1-9]|[12][0-9]|3[01])[\/](19|20)\d\d$/
  EMAIL_REGX = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  GENDER = ['Male','Female']

  ####--------- Relations
  #to execute callbacks for embed document we need to  enable cascade_callbacks
  embeds_one :kids_type, :class_name => "ProfileKidsType", :inverse_of => :profile, cascade_callbacks: true
  embeds_one :parent_type, :class_name => "ProfileParentType", cascade_callbacks: true
  embeds_many :user_tags
  embeds_one :meta_data , class_name: "MetaData", inverse_of: :meta_data, cascade_callbacks: true

  # embeds_many :parent_profiles
  # has_one :profile_org
  has_many :organization_memberships
  has_many :documents
  has_many :notifications
  #has_many :hospital_memberships
  has_many :invitations
  has_one :address

  ####--------- Scopes
  scope :subscribed_ae_emails ,where("parent_type.ae_notification_opt_out"=> false)
  scope :subscribed_org_emails ,where("parent_type.org_notification_opt_out"=> false)
  ####--------- Validations

  ####--------  Callbacks
  before_save :geocode, if:  Proc.new { |profile| profile.zipcode?}
  before_validation :assign_zipcode, if: Proc.new{|profile| profile.kids_type? and profile.kids_type.respond_to?(:zip)}
  before_create :respond_to_invitation, :if=> Proc.new { |profile| profile.parent_type?}
  # if profile is kids type then no need to save docs_shared_to into db and its blank
  before_save {|profile| profile.unset(:docs_shared_to) if profile.docs_shared_to.blank? } # doesn't hit DB

  ####----- index(es)
  index "organization_memberships.org_id" => 1
  index "organization_memberships.seasons.sessions.name" => 1
  index "organization_memberships.seasons.org_season_id" => 1
  index "organization_memberships.seasons.is_current" => 1
  index "organization_memberships.seasons.sessions.name" => 1
  index "parent_type.email" => 1
  index({docs_shared_to: 1})

  def trending
    feeds =[]
    coordinates = managed_kids.where(:geo.exists=>true).first
    feeds = Feed.near(coordinates.geo.reverse, 200).limit(5) if coordinates
    feeds += Feed.where(is_default: true)
    feeds
  end
  #returns full name of profile type
  def full_name
    return "#{kids_type[:fname]} #{pre_fill(:mname)} #{kids_type[:lname]}".strip rescue "" if kids_type
    return "#{pre_fill(:fname)} #{pre_fill(:mname)} #{pre_fill(:lname)}".strip rescue "" if parent_type
  end

  def profile_full_name
    return "#{kids_type.fname} #{kids_type.lname}".strip rescue "" if kids_type
    return "#{pre_fill(:fname)} #{pre_fill(:lname)}".strip rescue "" if parent_type
  end

  def short_name
    return "#{kids_type.fname} #{kids_type.lname.to_s[0].to_s.upcase}".strip rescue "" if kids_type
    return "#{parent_type.fname} #{parent_type.lname.to_s[0].to_s.upcase}".strip rescue "" if parent_type
  end

  def name_initials
    if kids_type
      name = "#{kids_type.fname.to_s[0].to_s.upcase}#{kids_type.lname.to_s[0].to_s.upcase}".strip rescue ""
      name = "#{kids_type.nickname.to_s[0].to_s.upcase}".strip rescue "" if name.blank?
      return name
    end
    return "#{parent_type.fname.to_s[0].to_s.upcase}#{parent_type.lname.to_s[0].to_s.upcase}".strip rescue "" if parent_type
  end

  def nickname
    return (kids_type.respond_to?(:nickname) ? (kids_type.nickname || kids_type.fname) : kids_type.fname) rescue "" if kids_type
    return parent_type.fname rescue "" if parent_type
  end

  def get_kid_value(attribute)
    if kids_type
      if attribute.eql?(:gender)
        gender(kids_type.respond_to?(attribute.to_sym) ? kids_type[attribute.to_sym] : "" )
      else
        kids_type.respond_to?(attribute.to_sym) ? kids_type[attribute.to_sym] : ""
      end
    end
  end

  def pre_fill(attribute)
    if kids_type
      kids_type.respond_to?(attribute.to_sym) ? kids_type[attribute.to_sym] :nil
    elsif parent_type
      parent_type.respond_to?(attribute.to_sym) ? parent_type[attribute.to_sym] : nil
    end
  end

  def pre_fill2(attribute, parent_profile)
    if parent_type
      addr = parent_profile.address
      addr.respond_to?(attribute.to_sym) ? addr[attribute.to_sym] : nil
    end
  end

  def relationship(kid_id)
    parent_type.profiles_manageds.where(kids_profile_id: kid_id).first.child_relationship  if parent_type
  end

  def manageable(kid_id)
    parent_type.profiles_manageds.where(kids_profile_id: kid_id).first.manageable  if parent_type
  end

  # --- for profile updation and more parents
  def kid=(params)
    self.kids_type.update_attributes(params)
    kid_changes = self.kids_type.previous_changes
    birthdate= self.kids_type.previous_changes["birthdate"]
    if !birthdate.blank?
      v1 = birthdate[0]
      v2 = birthdate[1].strftime("%m/%d/%Y")
      if v1 == v2
        kid_changes.delete('birthdate')
      end
    end
    add_changes(kid_changes)
  end

  def parents=(params)
    current_user_profile =  params[:current_user]
    params.reject{|key, value| key.eql?("current_user")}.values.each do |parent_params|
      parent_params[:info][:phone_numbers]= parent_params[:info][:phone_numbers].values if parent_params[:info].include?(:phone_numbers)
      assign_parent(parent_params, current_user_profile)
    end
  end

  def assign_parent(parent_params, current_user_profile)
    parent_params[:profiles_manageds].merge!(:kids_profile_id=>  self.id)
    if parent_params.include?(:id)
      parent = Profile.where(_id: parent_params[:id]).first

      previous_phone = parent.parent_type.phone_numbers
      p_contact = previous_phone.map(&:contact)
      p_type = previous_phone.map(&:type)
      p_key = previous_phone.map(&:key)

      parent.parent_type.update_attributes(parent_params[:info])
      changed_fields3 ={}
      parent_changes = parent.parent_type.previous_changes
      changed_fields3.merge!(parent_changes)

      recent_phone = parent.parent_type.phone_numbers
      n_contact = recent_phone.map(&:contact)
      n_type = recent_phone.map(&:type)
      n_key = recent_phone.map(&:key)

      changed_contact = p_contact.zip(n_contact)
      phone_numbrs = Hash[n_key.zip(changed_contact.map {|i| i.include?(',') ? (i.split /, /) : i})]
      changed_phones = phone_numbrs.reject{|k,v| v.to_a.uniq.count==1}
      parent_relation = parent.parent_type.profiles_manageds.where(kids_profile_id:  self.id).first.child_relationship
      changed_fields3.merge!({"phone_numbers"=>changed_phones}) unless changed_phones.blank?
      add_changes({parent_relation=>changed_fields3})

      parent.parent_type.profiles_manageds.where(kids_profile_id:  self.id).first.update_attributes( parent_params[:profiles_manageds])
    else
      parent = Profile.where("parent_type.email"=> parent_params[:info][:email].downcase).first #if  HospitalMembership.email_exists?(parent_params[:info])
      # Document Sharing
      if parent.nil?
        #Case1. User 1 does NOT yet exist when User 2 adds User 1 as a manager of User 2 child: Send User 1 regular "new user" email with temp password. This is how it works today.
        # Set sharing boxes on both User 1's preferences page and User 2's preferences page regarding each other to TRUE. They then automatically share.
        parent=  Profile.new(parent_type: parent_params[:info])
        return unless parent.parent_type
        parent.parent_type.profiles_manageds.build( parent_params[:profiles_manageds])
        parent.save
        current_user_profile.add_to_family_with_auto_acceptance(parent.id) unless parent.errors.any?
        parent.create_address(address_params)
        # hospital_id= current_user_profile.hospital_memberships.map(&:hospital_id).first
        # HospitalMembership.create(profile_id: parent.id, hospital_id: hospital_id)
        # current_user_profile.add_to_family(parent.id)
      else
        parent.parent_type.profiles_manageds.create!( parent_params[:profiles_manageds])
       # current_user_profile.add_to_family(parent.id)
        current_user_profile.push(docs_shared_to: parent.id) unless current_user_profile.docs_shared_to.include?(parent.id) # to avoid duplicates
        Notifier.delay.request_for_sharing_docs(current_user_profile,parent,self)
      end

    end
    if  parent_params[:profiles_manageds].has_key?(:manageable)
      create_user(parent.parent_type.as_json, current_user_profile)
    end
  end

  def create_user(params, current_user)
    if params["email"]
      user= User.where(email: params["email"].downcase).first
    else
      user = nil
    end

    if  user.nil?
      unless params.include?("password")
        new_pwd = Profile.generate_activation_code
        params.merge!("password" => new_pwd, "password_confirmation"=> new_pwd)
      end
      user= User.create(email:params["email"] , fname:params["fname"], password: params["password"], password_confirmation: params["password_confirmation"])
      user.create_role(:parent) unless user.errors.any?
      Notifier.delay.signup_additional_confirmation(self.nickname, current_user.parent_type.fname, current_user.parent_type.lname, params["password"], user.email, self.nickname)
    else
      Notifier.delay.signup_additional_confirmation_for_existing(self.nickname, current_user.parent_type.fname, current_user.parent_type.lname,user.email, self.nickname)
    end
  end

  def photograph=(params)
    if  !params.nil? and (!params[:source].blank? or !params[:canvas_url].blank?)
      document =self.documents.build(category_id: Category.find_by(name: Document::PHOTOGRAPH).id.to_s, rotate:params[:rotate], canvas_url:params[:canvas_url], taken_on: Date.today, multi_upload: true)
      document.source = params[:source]
      document.save
    end
  end

  def self.check_birth_date?(birth_date_format)
   (birth_date_format.match(Profile::DOB_REGX)) #and Date.strptime(birth_date_format, "%m/%d/%Y")<= Date.today)
  end

  #Kid applied organizations  if organization_id exists in organization_memberships or refer with foreign_key if both sides relations assigned
  def organizations
    Organization.find(organization_memberships.map(&:org_id))
  end

  #return true if
  def is_active_for_season?(season_id, org_id)
    org_membership = organization_membership(org_id)
    # return false if kid not yet applied to this organization
    # check kid status is active for particular season if already applied to this organization
    org_membership.nil? ? false : org_membership.seasons.where(org_season_id: BSON::ObjectId.from_string(season_id), status: 'active').exists?
  end

  #def applied_season(org_id,season_year)
  #  organization_memberships.where(profile_id: self.id,org_id: org_id).first.seasons.where(season_year: season_year).first
  #end

  #kid has only one organization_membership for each organization
  def organization_membership(org_id)
    organization_memberships.where(org_id: org_id).first
  end

  # returns all parents profile to this kid
  def parent_profiles
    # id-asc-> returns profiles created by ascending order
    Profile.where("parent_type.profiles_manageds.kids_profile_id" => self.id.to_s).asc(:_id)
  end

  # returns parents profile who can manange this kid
  def manageable_parents
    Profile.elem_match(:"parent_type.profiles_manageds"=>{kids_profile_id:id.to_s, manageable: true}).asc(:_id)
  end

  def creator
    Profile.elem_match(:"parent_type.profiles_manageds"=>{kids_profile_id:id.to_s, manageable: true, created:true}).asc(:_id).first
  end

  # returns all the kids managing by parent -profile
  def managed_kids
    Profile.in(id: managed_kids_ids).asc('kids_type.birthdate')
  end

  def created_kids
    Profile.in(id: created_kids_ids).asc('kids_type.birthdate')
  end

  # returns profiles of parents who manging his/her kids also
  # can use for family sections
  def family_profiles
    Profile.where(:id.ne=>id,:"parent_type.profiles_manageds".elem_match=>{:kids_profile_id.in=>managed_kids_ids.map(&:to_s), manageable: true}).asc(:_id)
  end

  def self_and_shared_docs
    others_shared_to_me = family_profiles.where(:docs_shared_to.in=>[self.id]).only(:id).map(&:id)
    shared_to_others  = self.docs_shared_to
    # get common profiles who sharing both sides
    (others_shared_to_me & shared_to_others).push(id) rescue []
  end

  # returns  document if any one of the documents tags includes PHOTOGRAPH('Photograph of child')
  def photograph
    @photograph ||= Document.where(profile_id: self.id).in(tags_array: [Document::PHOTOGRAPH]).first
  end

  # def photograph_url
  #   Rails.cache.delete("#{self._id}_photo") if Rails.cache.read("#{self._id}_photo").blank?
  #   Rails.cache.fetch("#{self.id}_photo"){photograph.source.cdn_url(:thumb) if !photograph.blank? and photograph.source.thumb.file and photograph.source.thumb.file.exists?}
  # end

  def photograph_url
    if !meta_data.blank?
      if !meta_data[:thumb_photo_url].blank?
        return meta_data.thumb_photo_url
      elsif !meta_data[:photo_url].blank?
        return meta_data.photo_url
      end
    # elsif !photograph.blank?
    #   photograph.add_photograph_url_meta_data
    #   photograph.source.url
    end
  end

  def aggregate_photograph_url
    photograph.add_photograph_url_meta_data unless photograph.blank?
  end

  def self.child_name(parent_profile)
    parent_profile.managed_kids.inject({}) {|m,e| m[e.kids_type.name] = e.kids_type.id.to_s; m }
  end

  #def self.child_fullname(parent_profile,season_id,organization_id=nil)
  #  parent_profile.managed_kids.inject({}) do |m,kid_profile|
  #    kids_name = kid_profile.kids_type.name
  #    kids_name += ' (currently applied)' if kid_profile.is_active_for_season?(season_id, organization_id)
  #    m[kids_name] = kid_profile.id.to_s
  #    m
  #  end
  #end

  # to select kids  via drop down from 'Apply using existing KidsLink membership link
  def child_applying(managed_kids123,season_id,organization_id=nil)
   managed_kids123.inject({}) do |m,kid_profile|
      kids_name = kid_profile.kids_type.name.blank? ? kid_profile.kids_type.nickname : kid_profile.kids_type.name
      kids_name += ' (currently applied)' if kid_profile.is_active_for_season?(season_id, organization_id)
      m[kid_profile.id.to_s] = kids_name
      m
   end
  end


  def self.generate_activation_code(size = 6)
    charset = %w{ 0 1 2 3 4 5 6 7 8 9 }
    (0...size).map { charset.to_a[rand(charset.size)] }.join
  end

  def parent_details
    Profile.where("parent_type.profiles_manageds.kids_profile_id"=>self.id.to_s)
  end

  # Takes an parent_types(user filled form details for parent bucket) as an parameter.
  # creates parent_type profiles if not existed,updates existing parent_types if any changes made to existing
  # finally returns an effected parent_type profiles as an array
  #ex: for example there is only one parent_type for child and on edit if user fills data of second parent_type we need to create new and update existing if any changes made
  def update_or_create_parent_types(parent_types_data,logged_in_user=nil)
    parent_type_profiles = []
    existed_profiles = []
    parent_types_data.each_with_index do |parent_type,index|
      parent_type_profile = parent_profiles[index].try(:parent_type)
      keys = parent_type.attributes.keys - ["_id", "_type", "ae_notification_opt_out", "org_notification_opt_out"]
      if parent_type_profile
        managed = parent_type_profile.profiles_manageds.where(kids_profile_id: self.id).first
        managed.child_relationship = parent_type['child_relationship'] unless managed.nil? and parent_type['child_relationship'].blank?
        keys.each do |k|
          parent_type_profile.read_attribute(k.to_sym)
          parent_type_profile.write_attribute(k.to_sym,parent_type[k])
          # if kid registered via hospital ,parent_type exists and parent phone numbers doesn't exists in reg form so assign them
          if parent_type_profile.phone_numbers.blank?
            parent_type_profile.phone_numbers =  parent_type.phone_numbers
          else
            parent_type_profile.phone_numbers.each_with_index do |phone,index|
              #check if parent phone_numbers exists in form
              unless parent_type.phone_numbers[index].nil? or parent_type.phone_numbers[index].blank?
                p_keys = parent_type.phone_numbers[index].attributes.keys - ["_id", "_type"]
                p_keys.each do |k|
                  phone.read_attribute(k.to_sym)
                  phone.write_attribute(k.to_sym,parent_type.phone_numbers[index][k])
                end
              end
            end
          end
        end
        parent_type_profiles << parent_type_profile if parent_type_profile.save
      elsif Profile.where("parent_type.email" => parent_type.email).first
        profile = Profile.where("parent_type.email" => parent_type.email).first
        existed_profiles << profile.id
        parent_type_profile = profile.parent_type
        if parent_type_profile and !parent_type['child_relationship'].blank?
          managed = parent_type_profile.profiles_manageds.create(child_relationship: parent_type['child_relationship'], kids_profile_id: self.id, manageable: true )
          keys.each do |k|
            parent_type_profile.read_attribute(k.to_sym)
            parent_type_profile.write_attribute(k.to_sym,parent_type[k])
            parent_type_profile.phone_numbers.each_with_index do |phone,index|
              #check if parent phone_numbers exists in form
              unless parent_type.phone_numbers[index].nil? or parent_type.phone_numbers[index].blank?
                p_keys = parent_type.phone_numbers[index].attributes.keys  - ["_id", "_type"]
                p_keys.each do |k|
                  phone.read_attribute(k.to_sym)
                  phone.write_attribute(k.to_sym,parent_type.phone_numbers[index][k])
                end
              end
            end
          end
          if logged_in_user and !logged_in_user.parent_profile.id.to_s.eql?(profile.id.to_s)
            current_parent =  logged_in_user.parent_profile
            unless current_parent.docs_shared_to.include?(profile.id) and profile.docs_shared_to.include?(current_parent.id)
              # send an email request to share docs
              current_parent.push(docs_shared_to: profile.id) unless current_parent.docs_shared_to.include?(profile.id) # to avoid duplicates
              Notifier.delay.request_for_sharing_docs(current_parent,profile,self)
            end
          end

          parent_type_profiles << parent_type_profile if parent_type_profile.save
        end
      else
        child_relationship = parent_type['child_relationship']
        profile = Profile.new(parent_type: parent_type)
        #create parent_type profile only if child_relationship given
        unless parent_type['child_relationship'].blank?
          if profile.save
            parent_type_profile = profile.parent_type
            parent_type_profile.profiles_manageds.create(child_relationship: child_relationship,kids_profile_id: self.id, manageable: true )
            #for multiple role if user has already role org_admin we need create Parent type Profile only no need to create user in this case
            unless logged_in_user.nil?
              # create user and send temporary password if email is given and already not exists
              if parent_type_profile.email.present? and !User.where(email: profile.parent_type.email).exists?
                current_parent_profile =  logged_in_user.parent_profile
                # enable doc sharing both sides
                current_parent_profile.push(docs_shared_to: profile.id)
                profile.push(docs_shared_to: current_parent_profile.id)

                new_pwd = Profile.generate_activation_code
                new_user = User.create!(email: profile.parent_type.email, fname: profile.parent_type.fname, lname: profile.parent_type.lname,password: new_pwd, password_confirmation: new_pwd)
                new_user.create_role(:parent)
                Notifier.signup_additional_confirmation(self.kids_type.name, new_user.fname, new_user.lname, new_pwd,profile.parent_type.email, self.kids_type.nickname).deliver
              end
            end
            parent_type_profiles << profile.parent_type
          end
        end
      end
    end
    return parent_type_profiles ,existed_profiles
  end

  # ================= To parent name and relation=========
  def parents_name_and_relation
    p = []
    parent_details.each do |par|
      parent={}
      parent[:relation] = par.parent_type.profiles_manageds.where(:kids_profile_id=>self.id).first.child_relationship
      parent[:full_name]  = par.full_name
      parent[:phone_numbers]= par.parent_type.phone_numbers
      parent[:email]= par.parent_type.email
      p << parent
    end
    #raise p.inspect
    return p
  end

  def managed_kids_ids
    @managed_kids_ids ||= parent_type.profiles_manageds.where(manageable:true).map(&:kids_profile_id)  rescue []
  end

  private

  class << self
    def check_required_if(req_hash, req_id, type, form_parm, field_val, count)
      #req_hash = id which belonged ex:child_relationship
      #req_id = id which have required_if condition ex:fname
      req_hash.each_with_index do |each_att,index|
        @req_val = form_parm[type][count.to_s].fetch(each_att['fieldname'], nil)
        if each_att['expr'].nil? and each_att['operator'] == 'nonempty'
          if @req_val == ""
            return false
          else
            if field_val != ""
              return false
            end
          end
        elsif each_att['expr'] != nil and each_att['operator'] == 'gte'
          if @req_val.to_i >= each_att['expr'].to_i
          else
            return false
          end
        elsif each_att['expr'] != nil and each_att['operator'] == 'lte'
          if @req_val.to_i <= each_att['expr'].to_i
          else
            return false
          end
        end
      end
    end
  end

  def self.age_calculation(dob)
    dob= Date.parse dob unless (dob.nil? || dob.class == Date)
    now = Time.now
    ydiff = now.year - dob.year
    mdiff = now.month - dob.month
    ddiff = now.day - dob.day
    if ((mdiff < 0) && (ydiff > 0))
      y = ydiff - 1
      m = mdiff + 12
    else
      y = ydiff
      m = mdiff
    end
    ys = "year";ms = "month";ds = "day"
    ys= ys.pluralize  if (y.abs > 1)
    ms = ms.pluralize  if (m.abs > 1)
    year_string = (y != 0) ? "#{y} #{ys}," : ""
    month_string = (m != 0) ? "#{m} #{ms}" : "0 months"
    #day_string = (d != 0) ? "#{d} #{ds}" : ""
    age = "#{year_string} #{month_string}"
    return age
  end

  #====== for geocoding purpose===============
  def assign_zipcode
    self.zipcode = self.kids_type.zip
  end

  def assign_photo
    doc = nil

    if  self.kids_type? and self.kids_type.respond_to?(:photo_id)
      doc = Document.where(kl_id: self.kids_type.photo_id).first
    elsif self.parent_type? and self.parent_type.respond_to?(:photo_id)
      doc = Document.where(kl_id: self.parent_type.photo_id).first
    end

    if doc
      self.documents.create(remote_source_url:doc.attachment.url, category_id: Category.find_by(name: Document::PHOTOGRAPH).id.to_s, taken_on: Date.today, multi_upload:true)
    end
  end

  def respond_to_invitation
    #rails4.0 update, we can't pass nil value in .set method
    if self.parent_type.referral_code.present?
      self.set(referal_code: self.parent_type.referral_code )
    end
    invitation= Invitation.where(token:self.parent_type.referral_code ).first
    invitation.update_attributes(status: "ACCEPTED")    unless invitation.nil?
  end

  def gender(value)
    case value
      when 'Male'
        'Boy'
      when 'Female'
        'Girl'
      else
        value
    end
  end

  def create_profile_manageds
    self.kids_type.managed_by.each do |params|
      profile= Profile.find_by(kl_id: params[:profile_id])
      #creator_id is current user profile id, who is creating the kid.
      creator = (respond_to?(:creator_id) and creator_id.to_s.eql?(profile.id.to_s))

      if profile and profile.parent_type?
        profile.parent_type.profiles_manageds.create(kids_profile_id:self.id,
                                                     child_relationship: params[:relationship],
                                                     manageable:true, created:creator)
      end
    end
  end

  def assign_address
    if self.address
      addr= self.address
      addr.update_attributes(self.parent_type.address)
      errors[:address]= addr.errors.full_messages.to_sentence if addr.errors.any?
    elsif !self.parent_type.address.blank?
      addr = self.create_address(self.parent_type.address)
      errors[:address]= addr.errors.full_messages.to_sentence if addr.errors.any?
    end
  end

  def extract_verified_phone_number
    self.verified_phone_number = extract_phone_number(self.verified_phone_number)
  end

  def auto_accept_invitation
    Invitation.where(receiver_phone_number: self.verified_phone_number).map do |inv|
      inv.update_attributes(status: Invitation::STATUS[:accepted])
    end
  end

  def update_known_counts
    ContactList.in(new_phone_numbers:[verified_phone_number])
               .update_all("$inc"=>{:known_count=>1},
                           "$push"=>{:existing_phone_numbers=> verified_phone_number},
                           "$pull"=>{:new_phone_numbers=> verified_phone_number})
  end

  def initiate_reminder
    InvitationNotifier.delay(run_at: 1.hour.from_now).first_signin_reminder(referral_code, parent_type.email, parent_type.fname)
  end


end


