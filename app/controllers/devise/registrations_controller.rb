class Devise::RegistrationsController < DeviseController

  prepend_before_filter :require_no_authentication, :only => [ :new, :create, :cancel ]
  prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy]
  layout Proc.new { |controller| session[:current_org].present? ? 'organization' : 'application' }
  # include ProfilesHelper

  layout :layout_by_resource

  def layout_by_resource
    if mobile_devices_format?
      "start_page_layout"
    else
      #"application_form_layout"
      'application'
    end
  end

  # GET /resource/sign_up
  def new
    @organization = Organization.find(params[:org_id])
    @kid_profile = Profile.find(params[:profile_id])
    @value = Hash.new
    @parent_profiles = @kid_profile.parent_profiles
    @parent_profiles.each do |each_parent|
      if !each_parent.parent_type.email.blank?
        each_parent.parent_type.profiles_manageds.each do |each_parent_relation|
          if(each_parent_relation.kids_profile_id.to_s == params[:profile_id])
            @value["#{each_parent_relation.child_relationship} : #{each_parent.parent_type.fname} #{each_parent.parent_type.lname}"] = each_parent.id
          end
        end
      end
    end
    resource = build_resource({})
    respond_with resource
  end

  # POST /resource
  def create 
    session[:existing_child] = nil
    build_resource
    @organization = Organization.find(params[:org_id])
    @kid_profile = Profile.find(params[:profile_id])  #kid profile
    @parent_profiles = @kid_profile.parent_profiles
    if resource.save
      #update the email in parent_type profile also if email already exists and changed with new after validation
      current_parent_profile = Profile.find(params[:parent_profile_id]) if params[:parent_profile_id].present?
      current_parent_profile.parent_type.update_attributes(email: resource.email) if current_parent_profile
      current_parent_profile.family_profiles.each do |other_parent|
        if params[:existed_profiles].present? and params[:existed_profiles].split(',').include?(other_parent.id.to_s)
          # send an email request to share docs
          current_parent_profile.push(docs_shared_to: other_parent.id) unless current_parent_profile.docs_shared_to.include?(other_parent.id) # to avoid duplicates
          Notifier.delay.request_for_sharing_docs(current_parent_profile,other_parent,@kid_profile)
        else
          current_parent_profile.push(docs_shared_to: other_parent.id)
          other_parent.push(docs_shared_to: current_parent_profile.id)
        end
      end
      # @profile.kids_type.update_attributes(:acknowledge_by => resource._id)
      #resource.memberships.create!(:roles => [Role.new(:role => 'organization', :organization => '502f80c3a788002d98000005')])
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource) if params["payment_form"].blank?
        respond_with resource, :location => after_sign_up_path_for(resource, params)
        #@parent_profiles.each do |each_parent|
        #     Profile.generate_activation_code if each_parent.parent_type.email != params[:user]['email']
        #end
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      # redirect_to new_user_registration_path(resource,{:id => params[:id], :org_name => params[:org_name] ,:parent_type => params[:realtion]})
      # clean_up_passwords resource
      respond_with resource, :location => new_user_for_error(resource)
    end
  end

  def new_user_for_error(resource)
    @value = Hash.new
    @parent_profiles. each do |each_parent|
      if !each_parent.parent_type.email.blank?
        each_parent.parent_type.profiles_manageds.each do |each_parent_relation|
          if(each_parent_relation.kids_profile_id.to_s == params[:profile_id])
            @value["#{each_parent_relation.child_relationship} : #{each_parent.parent_type.fname} #{each_parent.parent_type.lname}"] = each_parent.id
          end
        end
      end
    end
    new_user_registration_path(profile_id: @kid_profile.id, org_id: params[:org_id], season_id: params[:season_id], session: params[:session],
                               notification_id: params[:notification_id],existed_profiles: params[:existed_profiles],parent_profile_id: params[:parent_profile_id])
  end


  # GET /resource/edit
  def edit
    begin
      @profiles = Profile.where("parent_type.email" => current_user.email).first
      @child = Profile.child_name(@profiles)
      #@hospital_memberships = @profiles.map(&:hospital_memberships).flatten
    rescue
      #  if current_user is a not a parent_type i.e; may be admin then handle undefined method `parent_type' for nil:NilClass
    end
   render layout: 'organization'
  end

  # PUT /resource
  # We need to use a copy of the resource because we don't want to change
  # the current user in place.
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    unless resource_params[:current_password].eql?('')
      current_password = resource_params[:current_password]
      password = resource_params[:password]
      confirm_password = resource_params[:password_confirmation]
      if resource.update_with_password(resource_params)
        other_preferences_tasks if current_user.has_role?(:parent)
        if is_navigational_format?
          if resource.respond_to?(:pending_reconfirmation?) && resource.pending_reconfirmation?
            flash_key = :update_needs_confirmation
          end
          set_flash_message :notice, flash_key || :updated
        end
        sign_in resource_name, resource, :bypass => true
        unless mobile_devices_format?
          respond_with resource, :location => after_update_path_for(resource)
        else
          redirect_to root_url
        end
      else
        flash[:notice] = "#{resource.errors.full_messages.join("<br/>")}"
        redirect_to :back
      end
    else
      other_preferences_tasks if current_user.has_role?(:parent)
      redirect_to after_sign_in_path_for(resource)
    end
  end

  # DELETE /resource
  def destroy
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :destroyed if is_navigational_format?
    respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  def cancel
    expire_session_data_after_sign_in!
    redirect_to new_registration_path(resource_name)
  end

  def select_type

    @phone_no =""
    @str =""
    profile = Profile.find(params[:data])
    # raise profile.parent_type.email.inspect
=begin
    profile.parent_type.phone_numbers.each do |each_phone|
      @str<< each_phone.contact+','+each_phone.type+','
    end
    @phone_no=@str.split(',')

    render :js =>"
								document.getElementById('relation').value='#{profile.id}';
								document.getElementById('parent_fname').value='#{profile.parent_type.fname}'
								document.getElementById('parent_lname').value='#{profile.parent_type.lname}'
								document.getElementById('parent_email').value='#{profile.parent_type.email}'
								document.getElementById('phone_home').value='#{@phone_no[0]}'
								document.getElementById('phone_work').value='#{@phone_no[2]}'
								document.getElementById('phone_mobile').value='#{@phone_no[4]}'
								document.getElementById('home_type').value='#{@phone_no[1]}'
								document.getElementById('work_type').value='#{@phone_no[3]}'
                document.getElementById('mobile_type').value='#{@phone_no[5]}'
								"
=end
    render :js =>"
								document.getElementById('relation').value='#{profile.id}';
								document.getElementById('parent_fname').value='#{profile.parent_type.fname}'
								document.getElementById('parent_lname').value='#{profile.parent_type.lname}'
								document.getElementById('parent_email').value='#{profile.parent_type.email}'
								"
  end

  protected

  # Build a devise resource passing in the session. Useful to move
  # temporary session data to the newly created user.
  def build_resource(hash=nil)
    hash ||= resource_params || {}
    self.resource = resource_class.new_with_session(hash, session)
  end

  # The path used after sign up. You need to overwrite this method
  # in your own RegistrationsController.
  def after_sign_up_path_for(resource, params = {})
    cookies[:user_id] = resource.id
    new_payment_path(resource_id: resource.id, profile_id: params[:profile_id], org_id: params[:org_id],season_id: params[:season_id],session: params[:session],notification_id: params[:notification_id])
  end

  # The path used after sign up for inactive accounts. You need to overwrite
  # this method in your own RegistrationsController.
  def after_inactive_sign_up_path_for(resource)
    respond_to?(:root_path) ? root_path : "/"
  end

  # The default url to be used after updating a resource. You need to overwrite
  # this method in your own RegistrationsController.
  def after_update_path_for(resource)
    signed_in_root_path(resource)
  end

  # Authenticates the current scope and gets the current resource from the session.
  def authenticate_scope!
    send(:"authenticate_#{resource_name}!", :force => true)
    self.resource = send(:"current_#{resource_name}")
  end

  private

  def other_preferences_tasks
    if resource_params.include?(:kid) and resource_params[:kid].values.all?{|v| v.length >0 }
      kid = resource.add_kid(resource_params[:kid])
    end
    #resource.opting_partner_from_milestone(params.include?(:hospital_opt_out))
    resource.opting_ae_notification_emails(params.include?(:ae_notification_opt_out))
    ids = params[:docs_shared_to_ids].present? ? params[:docs_shared_to_ids].map{ |i| BSON::ObjectId.from_string(i)} : []
    resource.parent_profile.update_attribute(:docs_shared_to, ids) if resource.parent_profile
  end

  end
