class ProfilesController < ApplicationController

  skip_before_filter :authenticate_user!, :only => [:new, :edit ,:create, :update, :membership_create, :email_validate, :show, :create_profile]
  #before_filter :initialize_profile_n_org, :only => [:index]
  # before_filter :build_child, :only => [:new, :edit]

  def index
    @kid_profile = Profile.find(params[:profile_id])
    @parent_profile = current_user.parent_profile
    @organization = Organization.find(params[:org_id])
  end

  def show
    @organization = Organization.find(params[:org_id])
    @parent_profile = current_user.parent_profile
    @managed_kids = @parent_profile.managed_kids
    @child_applying = @parent_profile.child_applying(@managed_kids,params[:season_id],@organization.id)
    @child_applying['new'] = '**New child**'
  end

  def new
    session.delete(:error) unless params[:valid].present?
    @storedDataHash = session[:params_value]
    #session[:params_value] = nil
    session.delete(:params_value)
    @organization = if params[:org_id].present?
                      Organization.find(params[:org_id])
                    elsif params[:kidslink_network_id].present?
                      Organization.where(networkId: params[:kidslink_network_id]).first
                    elsif params[:id].present?
                      Organization.find(params[:id])
                    end
    @season = params[:season_id].present? ?  @organization.seasons.where(id: params[:season_id]).first : @organization.seasons.where(season_year: params[:season_year]).first
    # if user directly came to this page from search engine or from any link instead of org registration link
    # case1: if current_user exists then redirect to new_logged_in page to preload the profile
    # case2: if current_user not exists continue with same workflow
    redirect_to new_logged_in_profiles_path(org_id: @organization.id,season_id: @season.id) and return  if current_user #case1
    @form = @organization.json_templates.where(season_id: @season.id, workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form]).first
    # JSON parse template content
    @jsonTemplate = JSON.parse @form.content unless @form.nil?
    #render layout: 'application_form_layout'
  end

  def new_logged_in
    @organization = Organization.find(params[:org_id])
    @season = @organization.seasons.where(id: params[:season_id]).first
    if current_user and current_user.has_role?(:parent)
      @parent_profile = current_user.parent_profile
      @managed_kids = @parent_profile.managed_kids
    end
    if params[:valid].present?
      @storedDataHash = session[:params_value]
    else
      session.delete(:error)
      # stored data hash holder for template UI pre-populate
      tree_block = lambda{|h,k| h[k] = Hash.new(&tree_block) }
      @storedDataHash = Hash.new {|h,k| h[k] = Hash.new(&tree_block) }
      # pre-populate logged in user data?
      # populate parent(s) data
      if @parent_profile
        unless @parent_profile.address.nil?
          @storedDataHash[:univ][0][:address1] = @parent_profile.address.address1
          @storedDataHash[:univ][0][:address2] = @parent_profile.address.address2
          @storedDataHash[:univ][0][:city] = @parent_profile.address.city
          @storedDataHash[:univ][0][:state] = @parent_profile.address.state
          @storedDataHash[:univ][0][:zip] = @parent_profile.address.zipcode
        end

        # populate parent details
        @storedDataHash[:parent][0] = @parent_profile.parent_type
        # pick first relationship as default
        #@storedDataHash[:parent][0][:child_relationship] = parent.parent_type.profiles_manageds.first.child_relationship
        @storedDataHash[:parent][0][:child_relationship] = @parent_profile.parent_type.profiles_manageds.first.child_relationship unless @parent_profile.parent_type.profiles_manageds.blank?
        #populate parent phone number(s)
        @parent_profile.parent_type.phone_numbers.each_with_index {|val, iindex|
          jkey = val[:key]
          jkey||="phone#{iindex}"
          @storedDataHash[:parent][0][jkey.to_sym] = Hash.new
          @storedDataHash[:parent][0][jkey.to_sym]["type".to_sym] = val.type unless val.type.blank?
          @storedDataHash[:parent][0][jkey.to_sym]["contact".to_sym] = val.contact unless val.contact.blank?
        }
      else
        @storedDataHash[:parent][0][:email] = current_user.email
        @storedDataHash[:parent][0][:fname] = current_user.fname
        @storedDataHash[:parent][0][:lname] = current_user.lname
      end
    end
    # grab 'Application Form' type template for the applying season
    @form = @organization.json_templates.where(season_id: @season.id,workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form]).first
    # JSON parse template content
    @jsonTemplate = JSON.parse @form.content unless @form.nil?
    #render layout: 'application_form_layout'
  end

  def create_profile
    @organization = Organization.find(params[:org_id])
    json_template = JsonTemplate.find(params[:form_id])
    profile = Profile.new
    kid_profile = profile.build_kids_type
    organization_membership = profile.organization_memberships.build(org_id: @organization.id)
    #season = organization_membership.seasons.build(season_year: season_year, org_season_id: season_id)
    season = organization_membership.seasons.build(org_season_id: BSON::ObjectId.from_string(params[:season_id]))

    parents = Array.new
    kid_profile, parents, season,organization_membership, error_kid = parsedFromJSON(json_template, kid_profile, parents, season,organization_membership)
    if error_kid.blank?
      session.delete(:error)
    elsif error_kid.size.eql?(1) and error_kid['parent'] and error_kid['parent'].all?{|v| v.blank?}
      session.delete(:error)
    else
      store_validations(params['profile'])
      session[:error] = error_kid
      if current_user
        redirect_to new_logged_in_profiles_path(org_id: @organization.id,season_id: params[:season_id],valid: false) and return
      else
        redirect_to new_profile_path(org_id: @organization.id, season_id: params[:season_id],season_year: params[:season_year],valid: false) and return
      end
    end
    notification = NormalNotification.new(organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:form],json_template_id: json_template.id,status: 'active')
    season.notifications << notification
    if profile.save!
      profile.organization_memberships.push(organization_membership)
      #create default hospital membership
    end
    # parents
    #update or create parent_type_profiles
    parent_type_profiles ,existed_profiles =  profile.update_or_create_parent_types(parents,current_user)

    address = {}
    params[:profile][:univ][0].each{|key, value| address.merge!({key=> value}) if ['address1', 'address2', 'state', 'city', 'zip'].include?(key)}

    parent_type_profiles.each do |parent_profile|
      prof = Profile.where("parent_type._id" => parent_profile.id).first

      if prof.address.nil?
        prof.create_address(address)
      else
        prof.address.update_attributes(address)
      end

      # if !prof.hospital_memberships.exists?
      #   #prof.hospital_memberships.create(hospital_id: @organization.hospital_id,src_type: HospitalMembership::SOURCE_TYPES[:signup])
      #   prof.hospital_memberships.create(src_type: HospitalMembership::SOURCE_TYPES[:signup])
      # end


    end

    if current_user
      current_user.create_role(:parent) unless current_user.has_role?(:parent)
      session[:existing_child] = true
      redirect_to new_payment_path(resource_id: current_user.id, profile_id: profile.id, org_id: @organization.id,season_id: params[:season_id],
                                   session: season.try(:age_group_and_school_days),notification_id: notification.id)  and return
    else
      redirect_to new_user_registration_path(profile_id: profile.id, org_id: @organization.id, season_id: params[:season_id], session: season.try(:age_group_and_school_days),
                                             notification_id: notification.id,existed_profiles: existed_profiles.join(',')) and return
    end
  end


  def edit_existing
    @organization = Organization.find(params[:org_id])
    if current_user and current_user.has_role?(:parent)
      @parent_profile = current_user.parent_profile
      @managed_kids = @parent_profile.managed_kids
    end
    kid_profile = Profile.find(params[:profile_id])
    mem_org = kid_profile.organization_membership(params[:org_id])

    @season = @organization.seasons.where(id: params[:season_id]).first

    mem_seas = mem_org.seasons.where(org_season_id: BSON::ObjectId.from_string(params[:season_id])).first if mem_org

    @storedDataHash = session[:params_value]
    if @storedDataHash
      session[:params_value] = nil
    else
      @storedDataHash = nil
      session[:error] = nil
      @storedDataHash = hashtree
      @storedDataHash[:univ][0] = kid_profile.kids_type unless kid_profile.nil?
      # populate parent(s) data
      kid_profile.parent_profiles.each_with_index {|parent, index |

        unless parent.address.nil?
          @storedDataHash[:univ][0][:address1] = parent.address.address1
          @storedDataHash[:univ][0][:address2] = parent.address.address2
          @storedDataHash[:univ][0][:city] = parent.address.city
          @storedDataHash[:univ][0][:state] = parent.address.state
          @storedDataHash[:univ][0][:zip] = parent.address.zipcode
        end

        @storedDataHash[:parent][index] = parent.parent_type
        # pick first relationship as default
        # @storedDataHash[:parent][index][:child_relationship] = parent.parent_type.profiles_manageds.first.child_relationship
        @storedDataHash[:parent][index][:child_relationship] = parent.parent_type.profiles_manageds.where(kids_profile_id: kid_profile.id).first.child_relationship
        #populate parent phone number(s)
        parent.parent_type.phone_numbers.each_with_index {|val, iindex|
          jkey = val[:key]
          jkey||="phone#{iindex}"
          @storedDataHash[:parent][index][jkey.to_sym] = Hash.new
          @storedDataHash[:parent][index][jkey.to_sym]["type".to_sym] = val.type unless val.type.blank?
          @storedDataHash[:parent][index][jkey.to_sym]["contact".to_sym] = val.contact unless val.contact.blank?
        }

      }
      # populate org data
      @storedDataHash[:org][0] = mem_org  if mem_org
      # populate season data
      @storedDataHash[:seas][0] = mem_seas  if mem_org
    end
    # grab 'Application Form', default, type template for the applying season
    @form = @organization.json_templates.where(season_id: @season.id, workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form]).first
    # JSON parse template content
    @jsonTemplate = JSON.parse @form.content unless @form.nil?
    params[:profile_id] = kid_profile.id
    params[:submit_path] = edit_existing_submit_profiles_path
    #render layout: 'application_form_layout'

  end

  def edit_existing_submit
    @organization = Organization.find(params[:org_id])
    kid_profile = Profile.find(params[:profile_id]) if params[:profile_id].present?
    @parent_profile = current_user.parent_profile
    season_id = params[:season_id] unless params[:season_id].nil? or params[:season_id].blank?
    # grab kid application for this org-season
    organization_membership = kid_profile.organization_membership(@organization.id)
    if organization_membership
      #check if kid enrolled for the season
      applied_season = organization_membership.applied_season(season_id) || organization_membership.seasons.build(org_season_id: BSON::ObjectId.from_string(season_id))
    else
      organization_membership = kid_profile.organization_memberships.build(org_id: @organization.id)
      applied_season = organization_membership.seasons.build(org_season_id: BSON::ObjectId.from_string(season_id))
    end

    json = JsonTemplate.find(params[:form_id])
    kid_profile_type = kid_profile.kids_type
    parents = Array.new
    parent_type_profiles = [] #push the parent profiles if made any changes
    kid_profile_type, parent_types_data, applied_season,organization_membership, error_kid = parsedFromJSON(json, kid_profile_type, parents, applied_season,organization_membership)

    if error_kid.blank?
      session[:error] = nil
      @storedDataHash = nil
      session[:params_value] = nil
    elsif error_kid.size.eql?(1) and error_kid['parent'] and error_kid['parent'].all?{|v| v.blank?}
      session[:error] = nil
      @storedDataHash = nil
      session[:params_value] = nil
    else
      store_validations(params['profile'])
      session[:error] = error_kid
      redirect_to edit_existing_profiles_path(profile_id: kid_profile.id, org_id: @organization.id,season_id: season_id) and return
    end

    # check if kid ever submitted application for this org-season
    #save the records after fields are assigned
    kid_profile_type.save

    # Create Acknowledgment  if applying for new season
    if applied_season.new_record?
      applied_season.notifications << NormalNotification.new(organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:form],
                                                             json_template_id: json.id,status: 'active',user_id: current_user.id,acknowledgment_date: Time.now)
      #Acknowledgment.create!(season: season_year, org_id: @organization.id, kids_id: child.id, form_id: '', acknowledgment_name: 'application', acknowledgment_at: Time.now)
    else
      applied_season.save
    end
    organization_membership.save
    applied_season.save
    applied_season.unset(:is_current) if applied_season.respond_to?(:is_current)
    #update or create parent_type_profiles
    parent_type_profiles ,existed_profiles   =  kid_profile.update_or_create_parent_types(parent_types_data)

    address = {}
    params[:profile][:univ][0].each{|key, value| address.merge!({key=> value}) if ['address1', 'address2', 'state', 'city', 'zip'].include?(key)}

    parent_type_profiles.each do |parent_profile|
      prof = Profile.where("parent_type._id" => parent_profile.id).first
      if prof.address.nil?
        prof.create_address(address)
      else
        prof.address.update_attributes(address)
      end
    end

    session[:existing_child] = true
    notification = Notification.where(organization_membership_id: organization_membership.id,season_id: applied_season.id,json_template_id: json.id).first
    redirect_to new_payment_path(resource_id: current_user.id, profile_id: kid_profile.id, org_id: @organization.id,season_id: season_id,
                                 session: applied_season.try(:age_group_and_school_days),notification_id: notification.id)  and return
  end

  def hashtree
    tree_block = lambda{|h,k| h[k] = Hash.new(&tree_block) }
    return Hash.new {|h,k| h[k] = Hash.new(&tree_block) }
  end

  def form_data
    @organization = Organization.find( params[:org_id])
    @season = @organization.seasons.where(id: params[:season_id]).first
    @kid_profile = Profile.where(id: params[:profile_id]).first
    @parent_profile = current_user.parent_profile
    @address = @parent_profile.address
    @managed_kids = @parent_profile.managed_kids
    @organization_memberships = @kid_profile.organization_memberships.where(org_id: @organization.id)
    @storedDataHash = session[:params_value]
    if @storedDataHash
      session[:params_value] = nil
    else
      @storedDataHash = nil
      session[:error] = nil
      @storedDataHash = hashtree
      #populate univ data
      @storedDataHash[:univ][0] = @kid_profile.kids_type unless @kid_profile.nil?
      # populate parent(s) data
      @kid_profile.parent_profiles.each_with_index {|parent, index |

        unless parent.address.nil?
          @storedDataHash[:univ][0][:address1] = parent.address.address1
          @storedDataHash[:univ][0][:address2] = parent.address.address2
          @storedDataHash[:univ][0][:state] = parent.address.state
          @storedDataHash[:univ][0][:city] = parent.address.city
          @storedDataHash[:univ][0][:zip] = parent.address.zipcode
        end

        @storedDataHash[:parent][index] = parent.parent_type
        # pick child relationship from profiles_manageds
        @storedDataHash[:parent][index][:child_relationship] = parent.parent_type.profiles_manageds.where(kids_profile_id: @kid_profile.id).first.child_relationship
        #populate parent phone number(s)
        parent.parent_type.phone_numbers.each_with_index {|val, iindex|
          jkey = val[:key]
          jkey||="phone#{iindex}"
          @storedDataHash[:parent][index][jkey.to_sym] = Hash.new
          @storedDataHash[:parent][index][jkey.to_sym]["type".to_sym] = val.type unless val.type.blank?
          @storedDataHash[:parent][index][jkey.to_sym]["contact".to_sym] = val.contact unless val.contact.blank?
        }
      }
      @kid_profile.kids_type.phone_numbers.each_with_index do |phone_number,index|
        jkey = phone_number[:key]
        @storedDataHash[:univ][0][jkey.to_sym] = Hash.new
        @storedDataHash[:univ][0][jkey.to_sym]["type".to_sym] = phone_number.type unless phone_number.type.blank?
        @storedDataHash[:univ][0][jkey.to_sym]["contact".to_sym] = phone_number.contact unless phone_number.contact.blank?
      end

      # populate org data
      organization_membership = @kid_profile.organization_membership(@organization.id)
      @storedDataHash[:org][0] = organization_membership
      # populate season data
      applied_season = organization_membership.applied_season(BSON::ObjectId.from_string(params[:season_id]))
      @storedDataHash[:seas][0] = applied_season

      #prepopulate season bucket phone numbers in form if exists
      if applied_season and  !applied_season.phone_numbers.blank?
        begin
          applied_season.phone_numbers.each_with_index do |val, index|
            jkey = val[:key]
            jkey ||="phone#{index}"
            @storedDataHash[:seas][0][jkey.to_sym] = Hash.new
            @storedDataHash[:seas][0][jkey.to_sym]["type".to_sym] = val.type unless val.type.blank?
            @storedDataHash[:seas][0][jkey.to_sym]["contact".to_sym] = val.contact unless val.contact.blank?
          end
        rescue
          Rails.logger.info "Error: Form submission Seas Phone numbers are not valid as given in form"
        end
      end

    end

    @json = Notification.find(params[:notification_id]).json_template
    @jsonTemplate = JSON.parse @json.content
    params[:submit_path] = update_form_res_profiles_path
    #render :layout => "application_form_layout"
  end

  def update_form_res
    # raise params.inspect
    @organization = Organization.find(params[:org_id])
    @kid_profile = Profile.where(id: params[:profile_id]).first
    @parent_profile = current_user.parent_profile
    @managed_kids = @parent_profile.managed_kids
    organization_membership = @kid_profile.organization_membership(@organization.id)
    applied_season = organization_membership.applied_season(params[:season_id])
    notification =  Notification.find(params[:notification_id])
    json_template =  notification.json_template
    kid_profile_type = @kid_profile.kids_type
    parents = Array.new
    parent_type_profiles = [] #push the parent profiles if made any changes
    kid_profile_type, parent_types_data, applied_season,organization_membership, error_kid = parsedFromJSON(json_template, kid_profile_type, parents, applied_season,organization_membership)

    if error_kid.blank?
      session.delete(:error)
      @storedDataHash = nil
      session.delete(:params_value)
    elsif error_kid.size.eql?(1) and error_kid['parent'] and error_kid['parent'].all?{|v| v.blank?}
      session.delete(:error)
      @storedDataHash = nil
      session.delete(:params_value)
    else
      store_validations(params['profile'])
      session[:error] = error_kid
      redirect_to form_data_profiles_path(profile_id: @kid_profile.id, notification_id: notification.id,
                                          email: current_user.email, org_id: @organization.id, season_id:  params[:season_id]) and return
    end
    #update or create parent_type_profiles
    if applied_season and organization_membership
      #save the records after fields are assigned
      kid_profile_type.save
      #applied_season.save
      applied_season.unset(:ack_signature) if applied_season.respond_to?(:ack_signature)
      applied_season.unset(:ack_date) if applied_season.respond_to?(:ack_date)
      organization_membership.save

      parent_type_profiles ,existed_profiles   =  @kid_profile.update_or_create_parent_types(parent_types_data,current_user)

      address = {}
      params[:profile][:univ][0].each{|key, value| address.merge!({key=> value}) if ['address1', 'address2', 'state', 'city', 'zip'].include?(key)}

      parent_type_profiles.each do |parent_profile|
        prof = Profile.where("parent_type._id" => parent_profile.id).first
        prof.address.update_attributes(address) unless prof.address.nil?
      end

      #update notification acknowledgment
      notification.update_attributes(user_id: current_user.id,acknowledgment_date: Time.now)
      #increment submitted count to capture resubmitting the form or newly submitting
      notification.inc(submitted_count: 1)
      #update notifications status as submitted except Application Form
      unless json_template.workflow.eql?(JsonTemplate::WORKFLOW_TYPES[:appl_form])
        notification.update_attributes(is_accepted: 'submitted')
      end
      #session = applied_season.age_group_and_school_days
    end

    #To change alerts outstanding status
    status = applied_season.notifications.alerts.requested.count > 0 ? true : false
    applied_season.update_attribute(:alerts_outstanding, status)

    #send an email to org-admin once the form submitted or resubmitted
    Notifier.org_form_submission(@kid_profile,notification,@parent_profile, parent_type_profiles,applied_season,organization_membership,json_template, @organization,notification.submitted_count).deliver
    #send an email to all parents who managing this kid (for first time submission only)
    if notification.submitted_count == 1
      parents = @kid_profile.parent_profiles.subscribed_org_emails
      parents.each do |parent|
        recipient = parent.parent_type.email
        unless recipient.blank?
          Notifier.parent_form_submission(recipient,@kid_profile,notification,applied_season,organization_membership,json_template,@organization,@parent_profile).deliver
        end
      end
    end
    redirect_to child_org_dashboard_path(profile_id: @kid_profile.id,org: @organization.id)

  end



  def existing_apply_form
    if params[:profile_id].eql?('new')
      redirect_to new_logged_in_profiles_path(org_id: params[:org_id],season_id: params[:season_id])
    else
      kid_profile = Profile.find(params[:profile_id])
      if kid_profile.is_active_for_season?(params[:season_id],params[:org_id])
        redirect_to profile_path(kid_profile,org_id: params[:org_id],season_id: params[:season_id]),notice: 'applied'
      else
        redirect_to edit_existing_profiles_path(profile_id: kid_profile.id, org_id: params[:org_id],season_id: params[:season_id])
      end
    end
  end

  def child_dashboard
    return true if params[:child] == '**New child**'
    organization = Organization.where(:_id => session[:org_id]).first
    @kid_profile = Profile.find_by('kids_type._id' => BSON::ObjectId.from_string(params[:child]))
    begin
      dob = @kid_profile.kids_type.birthdate
      dob = dob.class == Time ? dob.to_date : Date.parse(dob)
      @age = Profile.age_calculation(dob)
    rescue
      Rails.logger.warn 'Invalid DOB field: #{dob}'
    end
    organization_applied_name = Organization.organization_applied(@kid_profile)

    @organization_memberships = @kid_profile.organization_memberships
    @parent_profile = Profile.where("parent_type.email" => current_user.email).first
    @child_name = Profile.child_name(@parent_profile)
    all_form = OrganizationMembership.find_by(:profile_id => @kid_profile.id)
    @orgnization_season,org_seas = [], []
    kid_applied_season_templates,seas_labels = [], []
    kid_applied_season_templates_for_univ = []

    all_form.to_a.each { |membr|
      @orgnization_season<<membr
      org = Organization.find(membr[:org_id])
      membr.seasons.each { |membr_seas|
        org.seasons.each {|org_seas|
          if org_seas._id== membr_seas.org_season_id
            kid_applied_season_templates.push(JsonTemplate.where(season_id: org_seas._id).first)
          end

        }
      }
    }
    all_form.to_a.each { |membr|
      org_seas<<membr
      org = Organization.find(membr[:org_id])
      membr.seasons.each { |membr_seas|
        org.seasons.each {|org_seas|
          if org_seas._id == membr_seas.org_season_id
            membr_seas.notifications.each do |e|
              if e.is_accepted != 'requested'
                kid_applied_season_templates_for_univ.push(JsonTemplate.where(id: e.json_template_id))
              end
            end
          end
        }
      }
    }
    # remove nil
    kid_applied_season_templates = kid_applied_season_templates.compact

    # stored data hash holder for UI view
    @storedDataHash = hashtree
    univ_columns,univ_keys = [],[]
    org_columns,org_keys = [],[]
    seas_columns,seas_keys = [],[]
    univ_values,common_univ_keys = [],[]
    unless @kid_profile.nil? || @kid_profile.kids_type.nil? || (k_attr_hash = @kid_profile.kids_type.safe_attr_hash).nil?
      kid_applied_season_templates_for_univ.each {|season_template|
        season_template.each do |aSeasonTemplate|
          t_json = JSON.parse aSeasonTemplate['content']

          univ_values = @kid_profile.kids_type.attributes.keys
          @univ_phone_numbers = bucket_phone_numbers_with_label(@kid_profile.kids_type,'univ',aSeasonTemplate)


          @address1 = @kid_profile.kids_type.address1
          @address2 = @kid_profile.kids_type.address2 if @kid_profile.kids_type.respond_to?(:address2)
          @full_address = @kid_profile.kids_type.city + ", " + @kid_profile.kids_type.state + " " + @kid_profile.kids_type.zip

          k_attr_hash.each{|k, v|
            t_field_hash = JsonTemplate.nested_hash_value(t_json, k, "univ")
            if t_field_hash.nil? || t_field_hash.empty? || t_field_hash["name"].nil?
              next
            end
            if t_field_hash['type'] == 'date'
              begin
                v = v.strftime("%B %d, %Y") if v.class == Time
                v = Date.strptime(v, '%m/%d/%Y').strftime("%B %d, %Y") if v.class == String
              rescue
                Rails.logger.warn 'Invalid DOB field: #{dob}'
              end
              @age = Profile.age_calculation(v)
            end

            label = t_field_hash["name"] #json_template label
            univ_key = t_field_hash["id"]
            if k == "city"
              k = "city"
              v = @full_address
            end

            @storedDataHash[:univ][0][label] = v
          }
        end
      }
    end

    #@storedDataHash[:univ][0].delete_if{|k, v| v == "each_field['id']"}
    # populate parent(s) data
    Profile.where("parent_type.profiles_manageds.kids_profile_id"=>@kid_profile.id.to_s).each_with_index do |parent, index |
      #@storedDataHash[:parent][index]= parent.parent_type.safe_attr_hash
      p_attr_hash = parent.parent_type.safe_attr_hash
      p_attr_hash.delete_if{|k, v| v.blank? or ['profiles_manageds', 'phone_numbers', 'fname'].include?(k)}
      # grab parents relationship type
      relationship = parent.parent_type.profiles_manageds.first.child_relationship
      father_full_name = parent.parent_type.fname + " " + parent.parent_type.lname
      kid_applied_season_templates.each {|aSeasonTemplate|
        t_json = JSON.parse aSeasonTemplate['content']
        p_attr_hash.each{|k, v|
          t_field_hash = JsonTemplate.nested_hash_value(t_json, k, "parent")
          if t_field_hash.nil? || t_field_hash.empty? || t_field_hash["name"].nil?
            next
          end
          if k == "email"
            v = "<a href = mailto:#{v}>#{v}</a>".html_safe
          end
          if k == "lname"
            v = father_full_name
          end
          if !v.start_with?("<a href = mailto:")
            @storedDataHash[:parent][index][relationship][t_field_hash["name"]]=v
          end

        }
      }

      parent.parent_type.phone_numbers.each_with_index {|val, iindex|
        jkey = val[:key]
        jkey||="Phone Numbers"
        p_type = val.type.blank? ? nil : "(#{val.type})"
        @storedDataHash[:parent][index][relationship][iindex] = "#{val.contact} #{p_type}" unless val.contact.blank?
      }
      kid_applied_season_templates.each {|aSeasonTemplate|
        t_json = JSON.parse aSeasonTemplate['content']
        p_attr_hash.each{|k, v|
          t_field_hash = JsonTemplate.nested_hash_value(t_json, k, "parent")
          if t_field_hash.nil? || t_field_hash.empty? || t_field_hash["name"].nil?
            next
          end
          if k == "lname"
            v = father_full_name
          end
          if k == "email"
            v = "<a href = mailto:#{v}>#{v}</a>".html_safe
          end

          if v.start_with?("<a href = mailto:")
            @storedDataHash[:parent][index][relationship][t_field_hash["name"]]=v
          end


        }
      }
    end
  end

  def child_org_dashboard
    @org = Organization.where(id: params[:org]).first#  ,enable this if need to show the logo on header
    @kid_profile = Profile.where(id: params[:profile_id]).first
    @organization_memberships = @kid_profile.organization_memberships.where(org_id: BSON::ObjectId.from_string(params[:org]))
    @parent_profile = current_user.parent_profile
    @managed_kids = @parent_profile.managed_kids
  end

  def top_dashboard
    @child = params[:child]
  end
  def launch
    #raise params.inspect
  end


  def validate_form
    @field_name = params[:field_name]
    if(params[:field_required]=="true")
      if(params[:field_type]== "password")
        if(params[:field_val]=="")
          @result ="#{params[:field_name]} is required."
        elsif(params[:field_val]!="" && params[:field_val].length<6)
          @result ="#{params[:field_name]} should be atleast 6."
        end

      elsif(params[:field_type]=="textarea")
        if(params[:field_val]=="")
          @result ="#{params[:field_name]} is required."
        elsif(params[:field_val]!=""  && params[:field_val].length <6)
          @result ="#{params[:field_name]} should be atleast 6."
        end
      elsif(params[:field_type]=="check_box")
        raise "here"
      elsif(params[:field_val]=="")
        @result ="#{params[:field_name]} is required."
      else
        @result= ""
      end
    end
    render :layout => false
  end

  def org_docdef_edit

  end

  def child_org_document_upload

  end

  def child_org_document_upload_notemplates

  end

  def child_org_document_view

  end

  def child_org_form_attachments

  end

  def child_org_form_attachments_notemplates

  end



end
