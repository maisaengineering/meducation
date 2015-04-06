class Organization
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  DISPLAY_ACTION = 'registering / applying'

  field :networkId, :type => String
  field :name, :type => String
  field :preffered_name, :type => String
  field :address1, :type => String
  field :address2, :type => String
  field :address3, :type => String
  field :phone_no, :type => String
  field :fax_no, :type => String
  field :email, :type => String
  field :description, :type => String
  field :action_type,default: DISPLAY_ACTION


  has_many :coupons, :class_name => "Admin::Coupon"
  embeds_many :weblinks, validate: false
  embeds_many :seasons, validate: false , cascade_callbacks: true

  has_many :json_templates #  , cascade_callbacks: true
  has_many :document_definitions #  , cascade_callbacks: true

  mount_uploader :logo, ImageUploader  ,dependent: :destroy

  accepts_nested_attributes_for :seasons , allow_destroy: true,:reject_if => proc { |attributes| attributes['season_year'].blank? }
  accepts_nested_attributes_for :weblinks, allow_destroy: true, :reject_if => proc { |attributes| attributes['link_name'].blank? }

  #validates_presence_of :name, :message => 'ERROR: Name is required'

  #To eliminate kidsLink organization from list
  default_scope where(:type.exists=>false)



  # unset action_type if its blank so that default 'DISPLAY_ACTION' will shown
  after_save { |record| record.unset(:action_type) if record.respond_to?(:action_type) and record.action_type.blank?  }

  # index(es)
  index "seasons.season_year" => 1
  index "seasons.sessions.name" => 1
  index "seasons.season_year" => 1
  index "seasons.is_current" => 1
  index "seasons.sessions.name" => 1

  def admins
    user_ids = Role.in(ref_ids: self.id).where(name: Role::NAMES[:org_admin]).map(&:user_id)
    User.in(id: user_ids)
  end

  # # heading on the landing page per org (action_type is dynamic attr saves in db only if admin changes it from default)
  # def display_action=(arg)
  #   self[:action_type] = arg.strip unless arg.blank?
  # end
  #
  def display_action
     self[:action_type] ||= DISPLAY_ACTION
  end




  # Global settings
  def auto_distribution?
    self.respond_to?(:auto_distribution) ? auto_distribution : false
  end

  # exclude
  def exclude_auto_distribution?
    self.respond_to?(:exclude_auto_distribution) ? exclude_auto_distribution : false
  end

  class << self

    # global Settings
    def global
      unscoped.where(type: 'global').first
    end

    def organization_applied(kid)
      orgnization_list = OrganizationMembership.where(:profile_kids_type_id => kid.kids_type._id)
      # OrganizationMembership fallback
      orgnization_list = OrganizationMembership.where(:profile_id => kid._id) if orgnization_list.blank?

      organization_name = Hash.new

      orgnization_list.each { |each_organization|
        @organization_details = Organization.where(:_id => each_organization.org_id).first
        organization_name[each_organization.org_id] = @organization_details.preffered_name
      }
      return organization_name
    end

    def organization_season(kid)
      orgnization_list = OrganizationMembership.where(:profile_kids_type_id => kid.kids_type._id)
      # OrganizationMembership fallback
      orgnization_list = OrganizationMembership.where(:profile_id => kid._id) if orgnization_list.blank?
      org_season = []
      orgnization_list.each do |each_organization|
        @organization_details = Organization.where(:_id => each_organization.org_id).first
        each_organization.seasons.each do |each_season|
          org_season << @organization_details.name.to_s+','+each_season.season_year.to_s+','+each_season.application_form_status.to_s+','+each_organization.org_id.to_s+','+@organization_details.phone_no.to_s+','+@organization_details.fax_no.to_s+','+@organization_details.address1.to_s+','+@organization_details.email.to_s+','+each_season.active_member_of_ppc.to_s+','+each_season.age_group_and_school_days.to_s+ ','+each_season.family_currently_enrolled.to_s+','+@organization_details.networkId.to_s+','+@organization_details.preffered_name.to_s+','+@organization_details.address2.to_s+','+@organization_details.address3.to_s+','+@organization_details.logo.to_s+','+each_season.secondary_choice_of_class_days.to_s
        end
      end
      return org_season
    end

    def generate_network_id
      @netid = Organization.last
      if @netid.blank?
        @orgid = 'kl_org_0'
      else
        @orgid = @netid.networkId
      end
      new_id =""
      n = @orgid.length
      last_count = @orgid.slice!(7..n)
      new_id << "kl_org_0" << (last_count.to_i+1).to_s
    end


    #not in use
    def autoform_acceptance(current_org, season)
      @organization = Organization.where(:_id => current_org).first
      @organization.seasons.each do |each_org_season|
        if (each_org_season.season_year == season)
          each_org_season.organization_forms.each do |each_org|
            if(each_org.workflow == "Auto at acceptance")
              @org_forms.create(:form_name => each_org.form_name, :form_status => 0)
            end
          end
        end
      end
    end
  end

  def self.export(season)
    @organization_membership = OrganizationMembership.where('seasons.org_season_id' => BSON::ObjectId.from_string(season))

    csv_string = CSV.generate do |csv|
      csv << ['Last Name', 'First Name', 'Preferred Name', 'KidsLink ID','Application Date','Application Time','Status', 'Session', 'Birthdate', 'Sex','Father First Name','Father last Name','Father Phone 1','Father phone 1 type','Father Phone 2','Father phone 2 type','Father Phone 3','Father phone 3 type','Father email','Mother First Name','Mother Last Name','Mother Phone 1','Mother phone 1 type','Mother Phone 2','Mother phone 2 type','Mother Phone 3','Mother phone 3 type','Mother email','Address Line 1','Address Line 2','City','State','Zip','Food allergies','Medical issues','Special needs','Other concerns','Are you enrolling siblings',"Sibling's name","Sibling's age group","Sibling's day",'Family currently enrolled?','Active members of Peachtree Presbyterian Church?','Admission agreement signature date','Admission agreement signature user','Coupon code','Registration fee']
      @organization_membership.each do |each_org_membership|
        @kid = Array.new
        @ack = Array.new
        @tan = Array.new
        @kids_profile_data = Profile.where('kids_type._id' => each_org_membership.profile_kids_type_id).first

        if @kids_profile_data.kids_type.status  == 'active'

          if @kids_profile_data.kids_type.created_at.nil?
            @application_date = ''
            @application_time = ''
          else
            @application_date = @kids_profile_data.kids_type.created_at.strftime('%m/%d/%Y')
            @application_time = @kids_profile_data.kids_type.created_at.strftime('%H:%M:%S %Z')
          end

          # COLLECTING ALL KIDS
          @kid << @kids_profile_data.kids_type.lname<<@kids_profile_data.kids_type.fname<<@kids_profile_data.kids_type.nickname<<@kids_profile_data.kids_type.kids_id<<@application_date<<@application_time \
          <<@kids_profile_data.kids_type.birthdate.to_date.strftime('%m/%d/%Y')<<@kids_profile_data.kids_type.gender

          @parent_profile_mother = Profile.where('parent_type.profiles_manageds.kids_profile_id' => @kids_profile_data._id.to_s,'parent_type.profiles_manageds.child_relationship' => 'Mother').first
          @parent_profile_father = Profile.where('parent_type.profiles_manageds.kids_profile_id' => @kids_profile_data._id.to_s,'parent_type.profiles_manageds.child_relationship' => 'Father').first

          #PARENT PROFILE DETAILS
          @parent_details_f = Organization.parent_data(@parent_profile_father)
          @parent_details_m = Organization.parent_data(@parent_profile_mother)
          @kid.concat(@parent_details_f)
          @kid.concat(@parent_details_m)


          @kid << @kids_profile_data.kids_type.address1 << @kids_profile_data.kids_type.address2 << @kids_profile_data.kids_type.city << @kids_profile_data.kids_type.state << @kids_profile_data.kids_type.zip \
          <<@kids_profile_data.kids_type.food_allergies.to_s << @kids_profile_data.kids_type.medical_issues << @kids_profile_data.kids_type.special_needs << @kids_profile_data.kids_type.other_concerns \

          #ORG DETAILS
          each_org_membership.seasons.each do |each_season|
            @kid << each_season.membership_enrollment.are_you_enrolling_siblings << each_season.membership_enrollment.sibling_name << each_season.membership_enrollment.sibling_age \
             << each_season.membership_enrollment.sibling_days << each_season.membership_enrollment.family_currently_enrolled << each_season.membership_enrollment.active_member_of_ppc
            original = each_season.membership_enrollment.age_group_and_school_days
            cleaned = ""
            original.each_byte { |x|  cleaned << x unless x > 127 }

            @kid.insert(6, cleaned)
            @kid.insert(6, each_season.application_form_status)
            break
          end

          #ACK DETAILS
          @Acknowledgment = Acknowledgment.where(:kids_id => @kids_profile_data._id,:acknowledgment_name => "application").first
          if @Acknowledgment.nil?
            @ack << '' << ''
            if @kids_profile_data.kids_type.status == 'active'
              @tan << "" << '125'
            else
              @tan << "" << ''
            end
          else
            @user =  User.where(:_id => @Acknowledgment.user_id).first
            @ack <<@Acknowledgment.acknowledgment_at.strftime('%m/%d/%Y') <<@user.email

            @transcation = Transaction.where(:email => @user.email).first unless  @user.nil?
            @tan << @transcation.coupon << @transcation.amount unless @transcation.nil?

          end

          @kid.concat(@ack)
          @kid.concat(@tan)

          csv << @kid
        end
      end
    end

    return csv_string
  end


  def sample(organization_membership,season)
    profile = organization_membership.profile
    kids_type = profile.kids_type
    columns = ['Last Name', 'First Name', 'Preferred Name', 'KidsLink ID','Application Date','Application Time','Status', 'Session', 'Birthdate', 'Sex','Father First Name','Father last Name','Father Phone 1','Father phone 1 type','Father Phone 2','Father phone 2 type','Father Phone 3','Father phone 3 type','Father email','Mother First Name','Mother Last Name','Mother Phone 1','Mother phone 1 type','Mother Phone 2','Mother phone 2 type','Mother Phone 3','Mother phone 3 type','Mother email','Address Line 1','Address Line 2','City','State','Zip','Food allergies','Medical issues','Special needs','Other concerns','Are you enrolling siblings',"Sibling's name","Sibling's age group","Sibling's day",'Family currently enrolled?','Active members of Peachtree Presbyterian Church?','Admission agreement signature date','Admission agreement signature user','Coupon code','Registration fee']

    pre_values =  predefined_values(profile,organization_membership)
    univ_columns = []
    univ_values = []

    parent_columns = []
    org_columns = []
    season_columns = []


    season.notifications.forms.submitted.each do |notification|
      json_template = notification.json_template
      kids_type.safe_attr_hash.each do |column,value|
        label = json_template.label_name('univ', column)
        if label
          univ_columns << label
          univ_values << value
        end
      end
    end
  end




  def export_enrollees_for(season,form_name)
    require 'csv'
    filename = "#{Rails.root}/tmp/export_profiles.csv"
    File.delete(filename) if File.exist?(filename)

    organization_memberships = OrganizationMembership.where(org_id: id.to_s,'seasons.org_season_id' => BSON::ObjectId.from_string(season))
    csv_string = CSV.open(filename,'w') do |csv|
      csv << ['Last Name', 'First Name', 'Preferred Name', 'KidsLink ID','Application Date','Application Time','Status', 'Session', 'Birthdate', 'Sex','Father First Name','Father last Name','Father Phone 1','Father phone 1 type','Father Phone 2','Father phone 2 type','Father Phone 3','Father phone 3 type','Father email','Mother First Name','Mother Last Name','Mother Phone 1','Mother phone 1 type','Mother Phone 2','Mother phone 2 type','Mother Phone 3','Mother phone 3 type','Mother email','Address Line 1','Address Line 2','City','State','Zip','Food allergies','Medical issues','Special needs','Other concerns','Are you enrolling siblings',"Sibling's name","Sibling's age group","Sibling's day",'Family currently enrolled?','Active members of Peachtree Presbyterian Church?','Admission agreement signature date','Admission agreement signature user','Coupon code','Registration fee']
      organization_memberships.each do |each_org_membership|
        kid = Array.new
        ack = Array.new
        tan = Array.new
        kids_profile_data = Profile.where('_id' => each_org_membership.profile_id).first
        kids_type = kids_profile_data.kids_type
        application_date = kids_type.created_at.strftime('%m/%d/%Y') unless kids_type.created_at.nil?
        application_time = kids_type.created_at.strftime('%H:%M:%S %Z') unless kids_type.created_at.nil?
        # COLLECTING ALL KIDS
        kid << kids_type.lname<< kids_type.fname<< kids_type.nickname << kids_type.kids_id << application_date << application_time \
          << kids_type.birthdate.to_date.strftime('%m/%d/%Y') << kids_type.gender
        parent_profile_mother = Profile.where('parent_type.profiles_manageds.kids_profile_id' => kids_profile_data._id.to_s,'parent_type.profiles_manageds.child_relationship' => 'Mother').first
        parent_profile_father = Profile.where('parent_type.profiles_manageds.kids_profile_id' => kids_profile_data._id.to_s,'parent_type.profiles_manageds.child_relationship' => 'Father').first

        #PARENT PROFILE DETAILS
        parent_details_f = Organization.parent_data(parent_profile_father)
        parent_details_m = Organization.parent_data(parent_profile_mother)
        kid.concat(parent_details_f)
        kid.concat(parent_details_m)


        kid << kids_type.address1 << kids_type.address2 << kids_type.city << kids_type.state << kids_type.zip \
          << kids_type.food_allergies.to_s <<  kids_type.medical_issues <<  kids_type.special_needs <<  kids_type.other_concerns \

        #ORG DETAILS
        each_org_membership.seasons.each do |each_season|

          kid << each_season.are_you_enrolling_siblings << each_season.sibling_name << each_season.age_group_and_school_days << each_season.sibling_days << each_season.family_currently_enrolled << each_season.active_member_of_ppc
          #@kid << each_season.application_form.status
          original = each_season.age_group_and_school_days
          cleaned = ""
          original.each_byte { |x|  cleaned << x unless x > 127 }
          kid.insert(6, cleaned)
          kid.insert(6, each_season.application_form_status)
          break
        end

        #ACK DETAILS
        acknowledgment = Acknowledgment.where(:kids_id => kids_profile_data._id,:acknowledgment_name => "application").first
=begin

        if acknowledgment.nil?
          ack << '' << ''
          #if each_org_membership.status == 'active'
          #  @tan << "" << '125'
          #else
          #  @tan << "" << ''
          #end
        else

          user =  User.where(:_id => acknowledgment.user_id).first
          ack << acknowledgment.acknowledgment_at.strftime('%m/%d/%Y')

          transaction = Transaction.where(:email => user.email).first unless user.nil?
          tan << transaction.coupon << transaction.amount unless transaction.nil?

        end

        kid.concat(ack)
        kid.concat(tan)
=end
        kid << '' << ''  << '' << ''
        csv << kid
        #end
      end
    end

    Notifier.delay.export_form_details(email,form_name,season)
  end




  def self.parent_data(profile)
    parent = Array.new
    extra_phone_key=[]
    extra_phone_value=[]
    if profile.nil?
      parent << ''
      #PARENT CONTACT
      parent << '' << ''<< '' << ''<< '' << '' << ''
      parent << ''
      extra_phone_value<<""<<""

    else
      parent << profile.parent_type.fname << profile.parent_type.lname
      #PARENT CONTACT
      #change for patch release

      i=1
      profile.parent_type.phone_numbers.each do|phno|
        if  i<=3
          parent<<phno.contact<<phno.type
        else
          extra_phone_key<< "#{profile.parent_type.profiles_manageds.first.child_relationship} Phone#{i}" << "#{profile.parent_type.profiles_manageds.first.child_relationship} Phone#{i} type"
          extra_phone_value<< phno.contact<<phno.type
        end
        i+=1;
      end
      (3 - profile.parent_type.phone_numbers.count).times do
        parent<<""<<""
      end
      extra_phone_key.flatten!
      extra_phone_value.flatten!


      #@extra_phone_key <<  extra_phone_key
      # @extra_phone_value << extra_phone_value
      # raise $extra_phone_key.inspect

      parent << profile.parent_type.email

    end

    return [parent,extra_phone_key,extra_phone_value]
  end
  class << self
    def membeship_data(season)

      season.membership_enrollment.nil? ?
          removed_att(season.attributes) :
          removed_att(season.membership_enrollment.attributes)
    end
    def split_array(lookup)
      lookup.split(",")
    end
    def label_name(bucket,key)
      JsonTemplate.nested_hash_value(JSON.parse(self.content), key, bucket)["name"] rescue key
    end
  end
  #returns first current-season across all the seasons embedded in org
  def current_season
    seasons.where(is_current: 1).first
  end

  def organization_memberships
    OrganizationMembership.where(org_id: self.id)
  end

  def export_profile_data(recipient,profile_ids,season_id,json_template=nil,single=false)

    # filename = "#{Rails.root}/tmp/export_profiles-#{Time.now.to_i}.xlsx"
    # File.delete(filename) if File.exist?(filename)
    form_name = json_template.nil? ? 'Profiles'  : json_template.form_name
    season = seasons.where(id: season_id).first
    predefined_columns = predefined_export_columns
    univ_keys_and_labels,org_keys_and_labels,seas_keys_and_labels = [],[],[]
    pre_univ_keys_and_labels,pre_org_keys_and_labels,pre_seas_keys_and_labels = [],[],[]
    predefined_columns.each do |k,v|
      univ_keys_and_labels <<  {v[:univ].to_s=>k}  unless v[:univ].nil?
      org_keys_and_labels <<  {v[:org].to_s=>k}  unless v[:org].nil?
      seas_keys_and_labels <<  {v[:seas].to_s=>k}  unless v[:seas].nil?


      pre_univ_keys_and_labels <<  {v[:univ].to_s=>k}  unless v[:univ].nil?
      pre_org_keys_and_labels <<  {v[:org].to_s=>k}  unless v[:org].nil?
      pre_seas_keys_and_labels <<  {v[:seas].to_s=>k}  unless v[:seas].nil?
    end


    pre_univ_keys,pre_org_keys,pre_seas_keys =[] ,[],[]
    #don't include or remove below key for other organizations except Peachtree Presbyterian Preschool
    #  predefined_columns.except!('Active members of Peachtree Presbyterian Church?') unless name.eql?('Peachtree Presbyterian Preschool')
    predefined_columns.values.each do |v|
      pre_univ_keys  << v[:univ]  unless v[:univ].nil?
      pre_org_keys  << v[:org]  unless v[:org].nil?
      pre_seas_keys  << v[:seas]  unless v[:seas].nil?
    end

    univ_columns,univ_keys = [],[]
    org_columns,org_keys = [],[]
    seas_columns,seas_keys = [],[]
    application_template =  season.json_templates.where(workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form]).first

    univ_keys_and_labels = application_template.export_keys_and_labels('univ',univ_keys_and_labels)
    org_keys_and_labels = application_template.export_keys_and_labels('org',org_keys_and_labels)
    seas_keys_and_labels = application_template.export_keys_and_labels('seas',seas_keys_and_labels)

    if json_template and json_template.id != application_template.id
      univ_keys_and_labels = json_template.export_keys_and_labels('univ',univ_keys_and_labels)
      org_keys_and_labels = json_template.export_keys_and_labels('org',org_keys_and_labels)
      seas_keys_and_labels = json_template.export_keys_and_labels('seas',seas_keys_and_labels)
    else
      # for single profile export get only forms of belonging profile else get all the forms of season of organization
      if single == true
        json_template_ids = OrganizationMembership.where(profile_id: profile_ids.first,org_id: self.id).first.notifications.where(:json_template_id.ne => application_template.id,:json_template_id.exists=>true,:json_template_id.in=>self.json_templates.map(&:id)).submitted.map(&:json_template_id)
        json_templates = JsonTemplate.in(id: json_template_ids)
        #json_templates = json_templates.where(:id.ne=> application_template.id)
      else
        json_templates = season.json_templates.where(:workflow.ne=>JsonTemplate::WORKFLOW_TYPES[:appl_form])
      end
      json_templates.each do |json_template|
        univ_keys_and_labels = json_template.export_keys_and_labels('univ',univ_keys_and_labels)
        org_keys_and_labels = json_template.export_keys_and_labels('org',org_keys_and_labels)
        seas_keys_and_labels = json_template.export_keys_and_labels('seas',seas_keys_and_labels)
      end
    end

    # ["a", "A"].inject(Hash.new){ |hash,j| hash[j.upcase] = j; hash}.values => "A"
    # ["a", "A"].inject(Hash.new){ |hash,j| hash[j.upcase] ||= j; hash}.values => "a"
    # remove duplicates with case insensitive i.e; from  [{'fname'=>'First Name'},{'birthdate'=>'Date of birth'},{'fname'=>'First name'}] to=>[{'fname'=>'First Name'},{'birthdate'=>'Date of birth'}]
    univ_keys_and_labels.uniq!{|k| k.values.map(&:upcase) | k.keys.map(&:upcase)}
    org_keys_and_labels.uniq!{|k| k.values.map(&:upcase) | k.keys.map(&:upcase)}
    seas_keys_and_labels.uniq!{|k| k.values.map(&:upcase) | k.keys.map(&:upcase)}

    # univ_keys_and_labels = univ_keys_and_labels.inject(Hash.new){ |hash,j| hash[j.values.first.upcase] ||= j; hash}.values
    # org_keys_and_labels = org_keys_and_labels.inject(Hash.new){ |hash,j| hash[j.values.first.upcase] ||= j; hash}.values
    # seas_keys_and_labels = seas_keys_and_labels.inject(Hash.new){ |hash,j| hash[j.values.first.upcase] ||= j; hash}.values



    # remove predefined keys if any exists
    univ_keys_and_labels = univ_keys_and_labels.uniq.reject{|x| pre_univ_keys_and_labels.include?(x) }
    org_keys_and_labels = org_keys_and_labels.uniq.reject{|x| pre_org_keys_and_labels.include?(x) }
    seas_keys_and_labels = seas_keys_and_labels.uniq.reject{|x| pre_seas_keys_and_labels.include?(x) }

    univ_keys_and_labels.uniq.each {|k| univ_keys += k.keys; univ_columns += k.values}
    org_keys_and_labels.uniq.each {|k| org_keys += k.keys; org_columns += k.values}
    seas_keys_and_labels.uniq.each {|k| seas_keys += k.keys; seas_columns += k.values}

    #parent data other than father and mother
    @extra_parent_columns_names=[]
    @extra_parent_values=[]
    @extra_phone_key=[]
    @extra_phone_value=[]
    #for individual profile export
    if single == true
      a=[]
      Axlsx::Package.new do |p|
        p.workbook.add_worksheet(name: "Profile Data") do |sheet|
          a <<  predefined_columns.keys  + univ_columns + org_columns + seas_columns + ["Modified Date","Modified Time"]
          Profile.where(:id.in=>profile_ids).each do |profile|
            a << export_individual_profile_data(predefined_columns,profile,application_template,season.id,univ_keys,org_keys,seas_keys)
          end
          sheet = get_csv(sheet,a)
        end
        # p.serialize(filename)
        return p
      end
    else
      a=[]
      Axlsx::Package.new do |p|
        p.workbook.add_worksheet(name: "Profile Data") do |sheet|
          a << predefined_columns.keys  + univ_columns + org_columns + seas_columns  + ["Updated Date","Updated Time"]
          Profile.where(:id.in=>profile_ids).each do |profile|
            a << export_individual_profile_data(predefined_columns,profile,application_template,season.id,univ_keys,org_keys,seas_keys)
          end
          sheet = get_csv(sheet,a)
        end
        Notifier.delay.export_form_details(recipient,name,form_name,season.season_year,p)
      end

    end
  end


  def export_individual_profile_data(predefined_columns,profile,application_template,season_id,univ_keys,org_keys,seas_keys)
    organization_membership = profile.organization_membership(id)# bucket org
    applied_season = organization_membership.seasons.where(org_season_id: season_id).first #bucket seas
    kids_type = profile.kids_type #bucket univ
    #grab notification for application form to fill acknowledgment details
    notification = Notification.where(organization_membership_id: organization_membership.id,season_id: applied_season.id,json_template_id: application_template.id).first
    predefined_values=  predefined_profile_data(predefined_columns,profile,notification,organization_membership,applied_season)
    # get the values at keys of specified bucket along with phone_numbers if there are any
    univ_values = grab_values_of_bucket_with_phone_numbers(kids_type,univ_keys)
    org_values = grab_values_of_bucket_with_phone_numbers(organization_membership,org_keys)
    seas_values = grab_values_of_bucket_with_phone_numbers(applied_season,seas_keys)

    modified_date  = kids_type.updated_at.blank? ? '' : kids_type.updated_at.strftime('%m/%d/%Y')
    modified_time = kids_type.updated_at.blank? ? '' : kids_type.updated_at.strftime('%H:%M:%S %Z')

    predefined_values + univ_values + org_values + seas_values << modified_date << modified_time
  end

  def grab_values_of_bucket_with_phone_numbers(bucket_object,bucket_keys)
    bucket_values = bucket_object.attributes.values_at(*bucket_keys)
    # Phone numbers ----------------------------------------------------------------------------------------------------
    bucket_object.phone_numbers.each do |phone_number|
      #check phone number of 'key' exists in bucket ,then find index of value form bucket_values and then assign value as contact & type
      if bucket_keys.include?(phone_number.key.to_s)
        p_type = phone_number.type.blank? ? nil : "(#{phone_number.type})"
        bucket_values[bucket_keys.index(phone_number.key.to_s)] = "#{phone_number.contact} #{p_type}"
      end
    end
    return bucket_values
  end



  def predefined_profile_data(predefined_columns,profile,notification,organization_membership,applied_season)
    kid = []
    kids_profile_data = profile
    kids_type = profile.kids_type #univ bucket
    transaction = Transaction.find_by(organization_id: organization_membership.org_id,user_id: notification.acknowledgment_by.id,
                                      profile_id: profile.id,season_id: applied_season.season_id ) rescue nil

    @parentdata = []
    parent_profiles = kids_profile_data.parent_profiles.to_a
    first_parent = parent_profiles.first.parent_type rescue nil
    parent_father = nil
    parent_mother = nil

    parent_profiles.each do |parent_profile|
      managed = parent_profile.parent_type.profiles_manageds.where(kids_profile_id: kids_profile_data.id.to_s).first
      if  managed.child_relationship.eql?('Mother')
        parent_mother = parent_profile.parent_type
      elsif managed.child_relationship.eql?('Father')
        parent_father = parent_profile.parent_type
      else
        relation =  managed.child_relationship
        pd = parent_data_new(parent_profile,relation)
        col_name = ["#{relation} First Name","#{relation} last Name","#{relation} Phone 1","#{relation} Phone 1 type","#{relation} Phone 2","#{relation} Phone 2 type","#{relation} Phone 3","#{relation} Phone 3 type","#{relation} email"]
        col_name << "#{relation} Occupation" if parent_profile.parent_type.respond_to?(:occupation)
        col_name << "#{relation} employer" if parent_profile.parent_type.respond_to?(:employer)
        index = @extra_parent_columns_names.index(col_name)
        if index.nil?
          @extra_parent_columns_names << col_name
          index=@extra_parent_columns_names.index(col_name)
        end
        @parentdata[index]=pd
      end
    end
    @extra_parent_values << @parentdata

    @address = Address.in(profile_id: kids_profile_data.parent_profiles.map(&:id)).desc(:updated_at).first
    address1 = !@address.nil? ? @address.address1 : ''
    address2 = !@address.nil? ? @address.address2 : ''
    city = !@address.nil? ? @address.city : ''
    state = !@address.nil? ? @address.state : ''
    zip = !@address.nil? ? @address.zipcode : ''

    #TODO need to refactor the code in simple way
    predefined_columns.values.each do |bucket|
      case  bucket.keys.first
        # univ  bucket -------------------------------------------------------------------------------------------------
        when :univ
          attr = bucket[:univ]
          if attr.eql?(:birthdate)
            kid << kids_type.birthdate.to_date.strftime('%m/%d/%Y')
          elsif attr.eql?(:address1)
            kid << address1
          elsif attr.eql?(:address2)
            kid << address2
          elsif attr.eql?(:city)
            kid << city
          elsif attr.eql?(:state)
            kid << state
          elsif attr.eql?(:zip)
            kid << zip
          elsif kids_type.respond_to?(attr)
            kid << kids_type.send(attr)
          else
            kid << ''
          end
        # season bucket  -----------------------------------------------------------------------------------------------
        when :seas
          attr = bucket[:seas]
          if attr.eql?(:created_date)
            kid << (applied_season.created_at.blank? ? 'N/A' : applied_season.created_at.strftime('%m/%d/%Y')) #Application Date
          elsif attr.eql?(:created_time)
            kid << (applied_season.created_at.blank? ? 'N/A' : applied_season.created_at.strftime('%H:%M:%S %Z')) #Application Time
          elsif attr.eql?(:status)
            kid << applied_season.application_form_status
          elsif attr.eql?(:ack_date)
            if notification
              kid << (notification.acknowledgment_by.nil? ? '' : notification.acknowledgment_date.strftime('%m/%d/%Y'))
            else
              kid << ''
            end
          elsif attr.eql?(:ack_signature)
            if notification
              kid << (notification.acknowledgment_by.nil? ? '' : notification.acknowledgment_by.email)
            else
              kid << ''
            end
          elsif attr.eql?(:coupon_code)
            kid << (transaction.nil? ? '' : transaction.coupon)
          elsif attr.eql?(:registration_fee)
            kid << (transaction.nil? ? '' : transaction.amount)
          elsif applied_season.respond_to?(attr)
            kid << applied_season.send(attr)
          else
            kid << ''
          end
        # org bucket  --------------------------------------------------------------------------------------------------
        when :org
          attr = bucket[:org]
          if organization_membership.respond_to?(attr)
            kid << organization_membership.send(attr)
          else
            kid << ''
          end
        # parent bucket(mother) ----------------------------------------------------------------------------------------
        when :parent_m
          attr = bucket[:parent_m]
          if attr.to_s.include?('type')
            kid << parent_phone_numbers_by_attr(parent_mother,:type,attr.to_s.last.to_i)
          elsif attr.to_s.include?('contact')
            kid << parent_phone_numbers_by_attr(parent_mother,:contact,attr.to_s.last.to_i)
          elsif parent_mother.respond_to?(attr)
            kid << parent_mother.send(attr)
          else
            kid << ''
          end
        # parent bucket(father) ----------------------------------------------------------------------------------------
        when :parent_f
          attr = bucket[:parent_f]
          if attr.to_s.include?('type')
            kid << parent_phone_numbers_by_attr(parent_father,:type,attr.to_s.last.to_i)
          elsif attr.to_s.include?('contact')
            kid << parent_phone_numbers_by_attr(parent_father,:contact,attr.to_s.last.to_i)
          elsif parent_father.respond_to?(attr)
            kid << parent_father.send(attr)
          else
            kid << ''
          end
        # parent bucket(default kid's first parent will be picked) -----------------------------------------------------
        when :parent
          attr = bucket[:parent]
          if attr.to_s.include?('type')
            kid << parent_phone_numbers_by_attr(first_parent,:type,attr.to_s.last.to_i)
          elsif attr.to_s.include?('contact')
            kid << parent_phone_numbers_by_attr(first_parent,:contact,attr.to_s.last.to_i)
          elsif first_parent.respond_to?(attr)
            kid << first_parent.send(attr)
          else
            kid << ''
          end
        else
          # do nothing
      end
    end
    return kid
  end

  def parent_data_new(profile,relation)
    parent = Array.new
    #extra_phone_key=[]
    #extra_phone_value=[]
    if profile.nil?
      parent << ''
      #PARENT CONTACT
      parent << '' << ''<< '' << ''<< '' << '' << ''
      parent << ''
      #extra_phone_value<<""<<""
    else
      parent << profile.parent_type.fname << profile.parent_type.lname
      #PARENT CONTACT
      #change for patch release
      i=1
      profile.parent_type.phone_numbers.each do|phno|
        if  i<=3
          parent<<phno.contact<<phno.type
        else
          col_name=["#{relation} Phone#{i}","#{relation} Phone#{i} type"]
          #raise @extra_phone_key.inspect
          index= @extra_phone_key.index(col_name)
          if index.nil?
            @extra_phone_key << col_name
            index=@extra_phone_key.index(col_name)
          end
          @extra_phone_value[index]=[phno.contact,phno.type]
        end
        i+=1;
      end
      (3 - profile.parent_type.phone_numbers.count).times do
        parent<<""<<""
      end
      parent << profile.parent_type.email
      #occupation/employer presents(for Cathadrel preschool)
      parent << profile.parent_type.occupation if profile.parent_type.respond_to?(:occupation)
      parent << profile.parent_type.employer if profile.parent_type.respond_to?(:employer)
    end

    return parent
  end

  private


  def get_csv(csv,a)

    unless @extra_phone_key.empty?
      @extra_phone_value.each_with_index do |values,ind|
        values.each_with_index do |ele,index|
          values[index]=[""]*2 if ele.nil?
        end
        diff=(@extra_phone_key.count-values.count)
        @extra_phone_value[ind] +=[[""]*2]*diff if diff>0
        @extra_phone_value[ind].flatten!
      end
      @extra_phone_key.flatten!
      @extra_phone_value.unshift(@extra_phone_key)  unless @extra_phone_key.empty?
    end

    #parent data other than father and mother
    unless @extra_parent_columns_names.empty?
      @extra_parent_values.each_with_index do |x,ind|
        x.each_with_index do |ele,index|
          x[index]=[""]*9 if ele.nil?
        end
        diff= (@extra_parent_columns_names.count-x.count)
        @extra_parent_values[ind] += [[""]*9]*diff if diff>0
        @extra_parent_values[ind].flatten!
      end
      #raise @extra_parent_values.inspect
      @extra_parent_columns_names.flatten!
      @extra_parent_values.unshift(@extra_parent_columns_names)
    end

    if !@extra_phone_value.empty? and !@extra_parent_values.empty?
      i=0
      #raise  @extra_parent_values.inspect
      a.each do |x|
        unless @extra_phone_value[i].empty? or @extra_parent_values[i].empty?
          csv.add_row(x + @extra_parent_values[i] + @extra_phone_value[i])
        else
          csv.add_row x
        end
        i+=1
      end
    elsif !@extra_phone_value.empty?
      i=0

      a.each do |x|
        unless @extra_phone_value[i].nil?
          csv.add_row(x + @extra_phone_value[i])
        else
          csv.add_row x
        end

        i+=1
      end
    elsif !@extra_parent_values.empty?
      i=0
      a.each do |x|
        unless @extra_parent_values[i].nil?
          csv.add_row x + @extra_parent_values[i]
        else
          csv.add_row x
        end
        i+=1
      end

    else
      a.each do |x|
        csv.add_row x
      end
    end
    return csv
  end

  def parent_phone_numbers_by_attr(parent_type,attr,index)
    return '' if parent_type.nil?
    index = index.eql?(0) ? 0 : (index -1)
    if  parent_type.phone_numbers[index].respond_to?(attr)
      parent_type.phone_numbers[index].send(attr)
    else
      ''
    end
  end

  def predefined_export_columns
    if respond_to?(:export_format)
       Hash[JSON.parse(export_format).map{|(k,v)| [k,Hash[v.map{|(k,v)| [k.to_sym,v.to_sym]}]]}]
    else
      {'Last Name'=>{:univ=>:lname}, 'First Name'=>{:univ=>:fname},
       'Preferred Name'=>{:univ=>:nickname}, 'KidsLink ID'=>{:univ=>:kids_id},'Application Date'=>{:seas=>:created_date},
       'Application Time'=>{:seas=>:created_time},'Status'=>{:seas=>:status}, 'Session'=>{:seas=>:age_group_and_school_days},
       'Birthdate'=>{:univ=>:birthdate}, 'Sex'=>{:univ=>:gender},
       'Father First Name'=>{:parent_f=>:fname},'Father last Name'=>{:parent_f=>:lname},'Father Phone 1'=>{:parent_f=>:contact1},'Father phone 1 type'=>{:parent_f=>:type1},
       'Father Phone 2'=>{:parent_f=>:contact2},'Father phone 2 type'=>{:parent_f=>:type2},'Father Phone 3'=>{:parent_f=>:contact3},'Father phone 3 type'=>{:parent_f=>:type3}, 'Father email'=>{:parent_f=>:email},
       'Mother First Name'=>{:parent_m=>:fname},'Mother Last Name'=>{:parent_m=>:lname},'Mother Phone 1'=>{:parent_m=>:contact1}, 'Mother phone 1 type'=>{:parent_m=>:type1},
       'Mother Phone 2'=>{:parent_m=>:contact2},'Mother phone 2 type'=>{:parent_m=>:type2},
       'Mother Phone 3'=>{:parent_m=>:contact3}, 'Mother phone 3 type'=>{:parent_m=>:type3},'Mother email'=>{:parent_m=>:email},
       'Address Line 1'=>{:univ=>:address1},'Address Line 2'=>{:univ=>:address2},
       'City'=>{:univ=>:city},'State'=>{:univ=>:state},'Zip'=>{:univ=>:zip},"Sibling's name"=>{:seas=>:sibling_name},
       'Admission agreement signature date'=>{:seas=>:ack_date},
       'Admission agreement signature user'=>{:seas=>:ack_signature},'Coupon code'=>{:seas=>:coupon_code},'Registration fee'=>{:seas=>:registration_fee}}
    end
  end




end
