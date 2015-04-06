require "csv"
require 'rubygems'
require 'json'
require 'set'
require 'will_paginate/array'

class OrganizationsController < ApplicationController
  load_and_authorize_resource

  include OrganizationsHelper
  skip_before_filter :authenticate_user!, :only => [:profile_request]
  #before_filter :build_nested_form, :only => [:new, :edit]
  before_filter :build_nested_form, :only => [:new]
  before_filter :enrollees_data, :only => [:org_enrollees, :change_status, :popup_send_form, :set_as_app]
  layout "organization"

  helper_method :sort_column, :sort_direction

  rescue_from JSON::ParserError, :with => :invalid_json_content

  def download_json
    send_file("#{Rails.root}/public/sample.json")
  end

  def index
    @organizations = Organization.all
  end

  def show
    @organization = Organization.find(params[:id])
  end

  def new
    @organization = Organization.new
    @organization.weblinks.build
    @season = @organization.seasons.build
    #2.times {@season.sessions.build}
  end

  def edit
    session[:current_org] = params[:id]
    @seasons = []
    @organization = Organization.find(session[:current_org])
    @seasons << @organization.seasons.build if @organization.seasons.blank?
  end

  def create
    @organization = Organization.new(params[:organization])
    if @organization.save
      @organization.seasons.create(params[:season])
      redirect_to @organization, :notice => 'Organization was successfully created.'
    else
      render 'new',notice: 'ERROR while creating organization'
    end
  end

  def update
    @organization = Organization.find(params[:id] || session[:current_org])
    @organization.update_attributes(params[:organization])
    if params[:select_season_year].eql?('create_new_season')
      season = @organization.seasons.create(params[:season])
    else
      season = @organization.seasons.where(id: params[:season_id]).first
     season.update_attributes(params[:season]) if season
    end
    #@organization.seasons.where(:id.ne=>season.id).update_all(is_current: 0) if season and season.is_current == 1
    #fix for => failed with error 9: "'$set' is empty. You must specify a field like so: {$mod: {<field>: ...}}"
    # update each attr instead of all at once
    if season and season.is_current == 1
      @organization.seasons.where(:id.ne=>season.id).each do |season|
        season.update_attribute(:is_current,0)
      end
    end
    redirect_to @organization, :notice => 'Organization was successfully created.'
  end


  def get_season_fields
    @organization = Organization.find(params[:org_id])
    if params[:season_id].eql?('create_new_season')
      @season = @organization.seasons.build
      #2.times {@season.sessions.build}
    else
      @season = @organization.seasons.find(params[:season_id])
    end
  end

  def profile_request
    @organization = params[:kidslink_network_id].present? ?  Organization.where(networkId: params[:kidslink_network_id]).first : Organization.where(id: params[:org_id]).first
    @season = params[:season_year].present? ? @organization.seasons.where(season_year: params[:season_year]).first : @organization.seasons.where(id: params[:season_id]).first
    render layout: 'application'
  end

  def org_form
    # lookup orginaization from session
    @organization = Organization.where(:_id => params[:id]).first

    if params[:season] and params[:form_id]

      # fetch requested season
      @season = @organization.seasons.where(id: params[:season]).first

      # grab template
      @jsonTemplate = JsonTemplate.where(:_id => params[:form_id], :season_id => @season._id).first
      raise "Template missing" if @jsonTemplate.nil?
    end
  end

  def org_form_edit
   # raise params.inspect
    # raise params[:workflow].inspect
    # try to parse content as JSON hash
    begin
      # try parsing as it is before flattening
      @jsonContent = JSON.parse(@jsonContentStr)
    rescue Exception => e
      Rails.logger.warn "Failed to parse JSON as typed by user. Err:#{e}"
      Rails.logger.info "Flattening it out before trying again"
      # make content string to JSON convertable
      @jsonContentStr = params[:content]#.gsub(/[^\s\w\d:{}\/\-\<\>\.\[\]\(\),"']/, '')
      # let default exception kick-in
      @jsonContent = JSON.parse(@jsonContentStr)
    end

    # lookup orginaization from session
    cur_org = Organization.where(:_id => params[:id]).first

    # fetch requested season
    template_season = cur_org.seasons.detect {|season| !season.nil? && season.season_year == @jsonContent['form']['season']}

    error_rest =  "Season,#{@jsonContent['form']['season']}, not found" if template_season.nil?

    if !error_rest.nil?
      redirect_to org_form_organizations_path(:is_new => 'yes', :id => params[:id], :error_msg=> error_rest)
    else
      # fetch season's json template by template identifier
      template = JsonTemplate.where(organization_id: cur_org.id,_id: params[:form_id],season_id: template_season.id).first
      # create template if not found?
      template ||= template_season.json_templates.create(organization_id: cur_org.id, season_id: template_season.id)
      if(params[:workflow] == JsonTemplate::WORKFLOW_TYPES[:appl_form])
        #except this change all  Application Forms to normal if found within the given season
        application_forms = JsonTemplate.ne(id: template.id).where(organization_id: cur_org.id,season_id: template_season.id,workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form])
        application_forms.update_all(workflow: JsonTemplate::WORKFLOW_TYPES[:normal])
      end
      # upsert json template attributes
      template.update_attributes(category: params[:category], form_name: @jsonContent['form']['name'], workflow: params[:workflow], content: @jsonContentStr)

      #redirect_to new_profile_path(:id =>session[:current_org], :season_year => @jsonContent['form']['season'], :form_preview =>"form_preview")
      redirect_to form_content_organizations_path({id: cur_org.id,season_id: template.season_id, season: @jsonContent['form']['season'], form_name: @jsonContent['form']['name'], templateId: template.id})
    end
  end


  def org_enrollees
    # clear previous selected data if admin visits newly(from launch page or after singn-in)
    if params[:clear_session].present?
      [:current_org, :session, :enrollement,:season].each { |k| session.delete(k) }
    end

    session[:current_org] = params[:id]
    session[:session] ||= 'All'
    session[:enrollement] ||= 'All'
    @organization = Organization.find(session[:current_org])
    @seasons = @organization.seasons.desc(:is_current)
    session[:season] ||= @seasons.first.id
    @org_data = form_details(session[:season])
  end

  def change_status
  end

  def change_status_res

    params[:kids_id].split(',').each do |each_kid|
      # Grab kid Profile
      profile = Profile.where(:id =>each_kid).first
      profile = Profile.where('kids_type._id' => BSON::ObjectId.from_string(each_kid)).first if profile.nil?
      next if profile.nil?

      # Grab parent, Who managing kid
      parent_profile = Profile.where("parent_type.profiles_manageds.kids_profile_id"=> profile.id.to_s).and("parent_type.org_notification_opt_out"=> false).first
      #parent_profile = Profile.where(:"parent_type".elem_match=>{:org_notification_opt_out=> false, "profiles_manageds.kids_profile_id"=> profile.id.to_s}).first
      # Grab organization details
      parent_profiles = Profile.where("parent_type.profiles_manageds.kids_profile_id"=> profile.id.to_s).and("parent_type.org_notification_opt_out"=> false)
      organization = Organization.find(session[:current_org])
      # Grab organization membership kid has been applied.
      organization_membership = profile.organization_membership(organization.id)
      # Get requested season
      membership_season = organization_membership.seasons.find_by(org_season_id: BSON::ObjectId.from_string(params[:season]))
      membership_season.update_attributes(application_status: params[:status]) unless params[:status].blank?
      season = organization.seasons.find_by(_id: params[:season]).season_year
      # @applied_session = @season.membership_enrollment['age_group_and_school_days'] unless @season.membership_enrollment.blank?
      applied_session = ''
      if membership_season.respond_to?(:age_group_and_school_days)
        if !membership_season.membership_enrollment.blank?
          applied_session = membership_season.membership_enrollment['age_group_and_school_days']
          membership_season.membership_enrollment.update_attributes(age_group_and_school_days: params[:session_data_change]) unless (params[:session_data_change]== "")
        else
          applied_session = membership_season.age_group_and_school_days if applied_session.blank?
          membership_season.update_attributes(age_group_and_school_days: params[:session_data_change]) unless (params[:session_data_change]== "")
        end
      end

      if params[:status].eql?('Registered')
        # Send mail to parent as kid registered
        web_link = organization.weblinks.blank? ? nil : organization.weblinks.first.link_url
        Notifier.status_registered(season, profile.kids_type.nickname, organization.name, applied_session, parent_profile.parent_type.email,web_link).deliver unless parent_profile.nil?
      elsif params[:status].eql?('Rejected') || params[:status].eql?('Withdrawn')
        #remove all notifications except application form for this applied season
        membership_season.notifications.not_in(json_template_id: [membership_season.application_form.json_template_id]).destroy_all
      elsif params[:status].eql?('Accepted')
        # send forms or docs with workflow auto
        org_season = organization.seasons.find_by(id: BSON::ObjectId.from_string(params[:season]))
        auto_json_templates  = organization.json_templates.auto.where(season_id: org_season.id)
        auto_json_templates.each do |json_template|
          membership_season.notifications << NormalNotification.create(organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:form],
                                                                       is_accepted:'requested',json_template_id: json_template.id,season_id: membership_season.id, profile_id: organization_membership.profile_id)
          membership_season.update_attributes(alerts_outstanding: true)
          parent_profiles.each do |parent|
            Notifier.delay.notification_form_alert(organization.preffered_name,organization.name,profile.kids_type.nickname, season,json_template.form_name, parent.parent_type.email) if !parent.parent_type.email.blank?
          end
        end
        auto_document_definitions = organization.document_definitions.auto.org_wide + org_season.document_definitions.auto
        auto_document_definitions.each do |document_definition|
          membership_season.update_attributes(alerts_outstanding: true)
          document_definition.is_for_season? ? membership_season.notifications << NormalNotification.create(organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:document],is_accepted: 'requested',document_definition_id: document_definition.id,season_id: membership_season.id, profile_id: organization_membership.profile_id) :
              organization_membership.notifications << NormalNotification.create(organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:document],is_accepted: 'requested',document_definition_id: document_definition.id, profile_id: organization_membership.profile_id)
          parent_profiles.each do |parent|
            Notifier.delay.notification_doc_alert(organization.preffered_name,organization.name,profile.kids_type.nickname, season,document_definition.name,parent.parent_type.email) if !parent.parent_type.email.blank?
          end
        end
      end

      # update season status
      membership_season.application_form.update_attributes(is_accepted: params[:status]) unless (params[:status]== "")

    end
    redirect_to org_enrollees_organizations_path(id: session[:current_org] ) and return true
  end

  def normal_form
    @season = params[:season]
    @org_data = form_details(params[:season])
    render :layout => false
  end

  def popup_send_form
    @org_data = form_details
  end

  def popup_send_form_res
    # forms or docs only with normal workflow comes into this action
    if params[:form_need].present? and  !params[:form_need].eql?('-----')
      type = params[:form_need].split('_')[0]
      form_or_doc_id =  BSON::ObjectId.from_string(params[:form_need].split('_')[1])
      params[:kids_selected].split(',').each do |kid_id|
        # Grab kid Profile
        profile = Profile.where(:id =>kid_id).first
        profile = Profile.where('kids_type._id' => BSON::ObjectId.from_string(kid_id)).first if profile.nil?
        next if profile.nil?

        parents =  Profile.where("parent_type.profiles_manageds.kids_profile_id"=>profile.id.to_s)
        organization_membership = profile.organization_membership(session[:current_org])
        season = organization_membership.seasons.find_by(org_season_id: BSON::ObjectId.from_string(params[:season]))
        organization = organization_membership.organization
        kid_name = profile.kids_type.fname
        #parent_email = parent_type.email
        if type.eql?('form') #create season document with json_template_id
          json_template  = JsonTemplate.find(form_or_doc_id)
          notification= NormalNotification.where(organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:form],is_accepted: 'requested', json_template_id: form_or_doc_id,season_id: season.id)
          unless notification.blank?
            notification.first.touch
          else
            season.update_attributes(alerts_outstanding: true)
            NormalNotification.create(profile_id: profile.id,organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:form],is_accepted: 'requested', json_template_id: form_or_doc_id,season_id: season.id)
          end
          parents.subscribed_org_emails.each do |parent|
            Notifier.delay.notification_form_alert(organization.preffered_name,organization.name,kid_name, params[:season],json_template.form_name,parent.parent_type.email)
          end
        else
          #its a document so check if its org-wide or season-wide and create notifications in respected bucket
          document_definition = DocumentDefinition.find(form_or_doc_id)
          if document_definition.is_for_season?
            notification= season.notifications.where(organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:document],
                                                     is_accepted: 'requested', document_definition_id: form_or_doc_id,season_id: season.id)
            unless notification.blank?
              notification.first.touch
            else
              season.update_attributes(alerts_outstanding: true)
              season.notifications << NormalNotification.create(profile_id: profile.id,organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:document],
                                                                is_accepted: 'requested', document_definition_id: form_or_doc_id,season_id: season.id)
            end
            parents.subscribed_org_emails.each do |parent|
              Notifier.delay.notification_doc_alert(organization.preffered_name,organization.name,kid_name, params[:season],document_definition.name,parent.parent_type.email)
            end
          else
            notification = organization_membership.notifications.where(organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:document],
                                                                       is_accepted: 'requested', document_definition_id: form_or_doc_id)
            unless notification.blank?
              notification.first.touch
            else
              season.update_attributes(alerts_outstanding: true)
              organization_membership.notifications << NormalNotification.create(profile_id: profile.id,organization_membership_id: organization_membership.id,category: Notification::CATEGORIES[:document],
                                                                                 is_accepted: 'requested', document_definition_id: form_or_doc_id)
            end
            parents.subscribed_org_emails.each do |parent|
              Notifier.delay.notification_doc_alert(organization.preffered_name,organization.name,kid_name, nil,document_definition.name,parent.parent_type.email)
            end
          end

        end
      end
    end
    redirect_to org_enrollees_organizations_path(id: session[:current_org] )
  end

  def is_organization_exist?(net_id)
    return Organization.where('networkId' => net_id).count > 0
  end

  def org_dashboard
  end

  def org_form_and_documents
    #raise params.inspect
    @organization = Organization.find(params[:id] || session[:current_org] )
    @seasons = @organization.seasons
    @default_season = params[:season].present? ? @seasons.find(params[:season]) : @seasons.first

    @document_definitions = @organization.document_definitions.org_wide + @default_season.document_definitions
  end


  def form_content
    # lookup org from session

    @cur_org = Organization.where(:_id => session[:current_org]).first

    # fetch requested season
    @cur_season = @cur_org.seasons.detect {|season| !season.nil? && season.season_year == params[:season]}

    # load template as JSON template
    @cur_template = JsonTemplate.where(:_id => params[:templateId], :season_id => @cur_season._id).first

    # read json
    # raise @cur_template.content.inspect
    @jsonTemplate = JSON.parse @cur_template.content

  end

  def selected_season
    @organization = Organization.where(:_id => params[:org_id]).first
    render :layout => false
  end

  def selected_data
    session[:season] = params[:season] || session[:season]
    session[:session] = params[:session] || session[:session]
    session[:enrollement] = params[:enrollement] || session[:enrollement]
    scope = get_enrollees_list(params)
    @organization_memberships = scope.paginate(:page => params[:page], :per_page => 1000)
    @parent_emails= get_parent_emails(@organization_memberships)
    render :layout => false
  end

  def selected_data_kid_ids
    scope = get_enrollees_list(params)
    render json: scope.collect{|e| e['profile_id'].to_s }
  end

  def selected_session
    session[:session] ||= 'All'
    @organization = Organization.where(:_id => params[:org_id]).first
    @all_season = ['All']
    season = @organization.seasons.where(id:  params[:season]).first
    @all_season += season.sessions.only(:session_name).map(&:session_name)
    render :layout => false
  end

  def selected_session_for_status
    @organization = Organization.find(params[:org_id])
    begin
      season = @organization.seasons.where(id: params[:season] || session[:season]).first
      @open_sessions = ['All'] + season.sessions.all.map(&:session_name)
    rescue
      @open_sessions = ['All']
    end
    render :layout => false
  end


  def change_form
    @json_form_for_season = JsonTemplate.where(:season_id => params[:season])
    @json_form_for_season.each do |each_json|
      each_json.update_attributes(:workflow => JsonTemplate::WORKFLOW_TYPES[:normal]) if each_json.workflow == JsonTemplate::WORKFLOW_TYPES[:appl_form]
    end
    JsonTemplate.where(:season_id => params[:season]).in(:_id => params[:templates]).each do |template|
      template.update_attributes(:workflow => JsonTemplate::WORKFLOW_TYPES[:appl_form])
    end
    render :js => ""
  end

  def change_workflow
    JsonTemplate.where(:season_id => params[:season]).in(:_id => params[:templates]).each do |template|
      template.update_attributes(:workflow => JsonTemplate::WORKFLOW_TYPES[:auto])
    end
    render :js => ""
  end

  def change_workflow_doc
    @organization = Organization.where(:_id => params[:org_id]).first
    @organization.seasons.each do |each_season|
      each_season.organization_documents.each do |each_org|
        each_org.update_attributes(:workflow => JsonTemplate::WORKFLOW_TYPES[:auto]) if (each_org.id.to_s == params[:doc_id])
      end if (each_season.id.to_s == params[:season])
    end
  end

  def set_as_app
    @organization = Organization.where(:_id => session[:current_org]).first
    @organization_seaons = organization_seasons @organization
  end

  def automate
    @organization = Organization.where(:_id => session[:current_org]).first
    @organization_seaons = organization_seasons @organization
  end

  def update_app
    redirect_to org_form_and_documents_path(session[:current_org])
  end

  def email_validate
    @org_email = Organization.where(:email => params[:email]).first
    if(@org_email)
      @result ="Already Existing"
    end
    render :layout => false
  end

  def org_child_profile
    # Grab kid profile
    @kid_profile = Profile.where(:id => params[:kid_id]).first
    @all_form =  OrganizationMembership.where(org_id: params[:id] || params[:org],:profile_id => @kid_profile.id).first
    all_form =  OrganizationMembership.where(org_id: params[:id] || params[:org],:profile_id => @kid_profile.id).first

    # Grab Parent details
    @parent_profile = Profile.where("parent_type.profiles_manageds.kids_profile_id"=> (@kid_profile.id).to_s)

    # collect array of OrganizationMembership, Kid applied
    orgnization_list_item = @kid_profile.organization_membership(params[:org])
    @orgnization_list = Array(orgnization_list_item)
    @orgnization_season = []
    org_seas = []
    kid_applied_season_templates = []
    kid_applied_season_templates_for_univ = []
    # to -> @all_form because already we fetched based on profile_id and profile_kids_type_id

    @all_form.to_a.each { |membr|
      @orgnization_season<<membr
      org = Organization.find(membr[:org_id])
      membr.seasons.each { |membr_seas|
        org.seasons.each {|org_seas|
          if org_seas.id.to_s == membr_seas.org_season_id.to_s
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
          if org_seas.id.to_s == membr_seas.org_season_id.to_s
            membr_seas.notifications.each do |e|
              if e.is_accepted != 'requested'
                kid_applied_season_templates_for_univ.push(JsonTemplate.where(id: e.json_template_id))
              end
            end
          end

        }
      }
    }
    @orgnization_season||= OrganizationMembership.where(org_id: params[:id],:profile_id => @kid_profile.id, :seasons=>{:status=>"active"}).not_in('seasons.status' => 'inactive')
    @storedDataHash = hashtree
    kid_applied_season_templates = kid_applied_season_templates.compact

=begin
    jsonTemplate = JsonTemplate.find_by(organization_id: params[:org])
    # collect seasonal data
    @orgnization_season.each do |organization_membership|
      organization_membership.seasons.active.each do |season|
        season.attributes.each do |element|
          seas_data = jsonTemplate.label_name('seas', element[0])
          @storedDataHash[:seas][0][seas_data] = element[1]
        end

      end
    end
=end



    addr = Address.in(profile_id: @kid_profile.parent_profiles.map(&:id)).desc(:updated_at).first
    if addr
      @address1  = addr.address1
      @address2 = addr.address2 if addr.respond_to?(:address2)
      @full_address = []
      @full_address << addr.city << addr.state << addr.zip
      @full_address = @full_address.compact.reject{ |c| c.empty? }.join(", ")
    end

    @univ_phone_numbers = {}
    unless @kid_profile.nil? || @kid_profile.kids_type.nil? || (k_attr_hash = @kid_profile.kids_type.safe_attr_hash).nil?
      kid_applied_season_templates_for_univ.each {|season_template|
        season_template.each do |aSeasonTemplate|
          t_json = JSON.parse aSeasonTemplate['content']
          @kid_profile.kids_type.phone_numbers.each do |phone_number|
            label_of_phone = aSeasonTemplate.label_name('univ',phone_number.key.to_s)
            if label_of_phone
              @univ_phone_numbers[label_of_phone] = "#{phone_number.contact}"
              @univ_phone_numbers[label_of_phone] += " (#{phone_number.type})" unless phone_number.type.blank? and phone_number.contact.blank?
            end
          end

          #@address1  = @kid_profile.kids_type.address1
          #@address2 =  @kid_profile.kids_type.address2 if @kid_profile.kids_type.respond_to?(:address2)
          #@full_address = @kid_profile.kids_type.city + ", " + @kid_profile.kids_type.state  + "  " + @kid_profile.kids_type.zip

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
            label = t_field_hash["name"]
            if  k == "city"
              k = "city"
              v = @full_address
            end

            @storedDataHash[:univ][0][label] = v
          }
        end
      }
    end

    @storedDataHash[:univ][0].delete_if{|k, v| v == "each_field['id']"}

    Profile.where("parent_type.profiles_manageds.kids_profile_id"=>@kid_profile.id.to_s).each_with_index {|parent, index |
      p_attr_hash = parent.parent_type.safe_attr_hash
      # grab parents relationship type
      relationship = parent.parent_type.profiles_manageds.where(kids_profile_id: @kid_profile.id.to_s).first.child_relationship
      kid_applied_season_templates.each {|aSeasonTemplate|
        t_json = JSON.parse aSeasonTemplate['content']
        k_attr_hash.each{|k, v|
          t_field_hash = JsonTemplate.nested_hash_value(t_json, k, "org")
          if t_field_hash.nil? || t_field_hash.empty? || t_field_hash["name"].nil?
            next
          end
          @storedDataHash[:parent][index][parent][t_field_hash["name"]]=v

        }
      }
    }
    # populate parent(s) data
    Profile.where("parent_type.profiles_manageds.kids_profile_id"=>@kid_profile.id.to_s).each_with_index {|parent, index |
      p_attr_hash = parent.parent_type.safe_attr_hash
      p_attr_hash.delete_if{|k, v| v.blank? or ['profiles_manageds', 'phone_numbers', 'fname'].include?(k)}

      # grab parents relationship type
      relationship = parent.parent_type.profiles_manageds.where(kids_profile_id: @kid_profile.id.to_s).first.child_relationship
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
          if  k == "lname"
            v = father_full_name
          end
          if v.instance_of?(String) and !v.start_with?("<a href = mailto:")
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
          if  k == "lname"
            v = father_full_name
          end
          if k == "email"
            v = "<a href = mailto:#{v}>#{v}</a>".html_safe
          end

          unless v.instance_of?String and v.start_with?("<a href = mailto:")
            @storedDataHash[:parent][index][relationship][t_field_hash["name"]]=v
          end

        }
      }
    }
  end
  #TODO need to remove below action, before used to emails for contact via email tab at org admin dashboard.
  def contact_vi_mail
    all_parent_email = Profile.where(:parent_type.exists=>true,
                                      :"parent_type.profiles_manageds.kids_profile_id".in=>params[:child_ids])
                        .map(&:parent_type).map(&:email).reject(&:blank?)

    # if all_parent_email.count>30
    #
    #   head 200, :content_type => 'text/html'
    # else
      render text: all_parent_email.join(',')
    # end

  end

  def export_profile_data_csv
    organization = Organization.find(params[:id])
    profile = Profile.find(params[:profile_id])
    csv_string = organization.export_profile_data(current_user.email,[params[:profile_id]],params[:season_id],nil,true)
    #send_data "#{Rails.root}/tmp/export_profiles.xlsx",
         #     :type => 'text/xlsx; charset=iso-8859-1; header=present',:disposition => "attachment; filename=#{profile.kids_type.kids_id}profile.xlsx"
    send_data csv_string.to_stream.read, filename: "#{profile.kids_type.kids_id}profile.xlsx", type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

  end

  def export_csv_season
    organization = Organization.find(params[:id])
    organization.delay.export_profile_data(current_user.email,params[:profile_ids].split(',').flatten,params[:season_id])
    render js: 'alert("Export queued. Please check your email shortly to download.");'
  end

  def export_template
    organization = Organization.find(params[:id])
    template = JsonTemplate.find(params[:form_id])
    organization.delay.export_profile_data(current_user.email,template.organization_memberships.map(&:profile_id),params[:season],template)
    render js: 'alert("Export queued. Please check your email shortly to download.");'
  end





  def print_profile_data
    @json_template = JsonTemplate.find(params[:json_template_id])
    @organization = Organization.find(params[:id] || session[:org_id])
    @season = @organization.seasons.find_by(id: BSON::ObjectId.from_string(params[:season_id]))
    @organization_memberships = @json_template.organization_memberships.active
    render :layout => false
  end



  def hashtree
    tree_block = lambda{|h,k| h[k] = Hash.new(&tree_block) }
    return Hash.new {|h,k| h[k] = Hash.new(&tree_block) }
  end

  def add_select_boxes
    @val = params[:incre]

  end

  def show_lookups
    org = Organization.where(:_id => session[:current_org]).first
    #lookup = Organization.find_lookup(org)
    @storedDataHash = hashtree
    org['lookup_ids'].each {|key|
      @storedDataHash[:lookup] = org.send(key)

    }

  end

  def form_data
    @organization = Organization.find(params[:org_id])
    @json_template =  JsonTemplate.find(params[:json_template_id])
    @season = @organization.seasons.find_by(_id: BSON::ObjectId.from_string(params[:season_id]))
    @child = Profile.find(params[:child]) if params[:child].present?
    @addr = Address.in(profile_id: @child.parent_profiles.map(&:id)).desc(:updated_at).first
    params[:kid_id] = @child.id
    params[:submit_path] = update_form_res_organizations_path
    render :layout => false

  end
  def update_form_res

    @organization = Organization.find(params[:org_id])
    child = Profile.where('_id' => BSON::ObjectId.from_string(params[:kid_id])).first unless params[:kid_id].nil?
    @parent_profile = Profile.where("parent_type.email" => current_user.email).first
    season_id = params[:season] unless params[:season].nil? or params[:season].blank?
    #season_year||= session[:season_year]
    # grab kid application for this org-season
    organization_membership = child.organization_membership(@organization.id)
    applied_season = organization_membership.applied_season(org_season_id )
    json = JsonTemplate.find(params[:form_id])
    kid_profile_type = child.kids_type
    parents = Array.new
    parent_type_profiles = [] #push the parent profiles if made any changes
    kid_profile_type, parent_types, applied_season,organization_membership, error_kid = parsedFromJSON(json, kid_profile_type, parents, applied_season,organization_membership)
    unless error_kid.blank?
      store_validations(params['profile'])
      session[:error] = error_kid
      redirect_to form_data_organizations_path(child: kid_profile_type.id.to_s, json_template_id: json.id, org_id: @organization.id, season_id: season_id) and return
    end

    if applied_season and organization_membership
      #save the records after fields are assigned
      kid_profile_type.save
      applied_season.save
      organization_membership.save
      child.parent_profiles.each_with_index do |profile,index|
        parent_type =  parent_types[index]#nil or blank if parent bucket details not exists in form
        unless parent_type.nil? or parent_type.blank? # if parent details exists in form then
          keys = parent_type.attributes.keys - ["_id", "_type"]
          parent_profile = profile.parent_type
          managed = parent_profile.profiles_manageds.where(kids_profile_id: child.id).first
          managed.child_relationship = parent_type['child_relationship'] unless managed.nil? and  parent_type['child_relationship'].blank?
          keys.each do |k|
            parent_profile.read_attribute(k.to_sym)
            parent_profile.write_attribute(k.to_sym,parent_type[k])
            parent_profile.phone_numbers.each_with_index do |phone,index|
              #check if parent phone_numbers exists in form
              unless parent_type.phone_numbers[index].nil? or parent_type.phone_numbers[index].blank?
                p_keys = parent_type.phone_numbers[index].attributes.keys  - ["_id", "_type"]
                p_keys.each do |k|
                  phone.read_attribute(k.to_sym)
                  phone.write_attribute(k.to_sym,parent_type.phone_numbers[index][k])
                end
              end
            end
            parent_type_profiles << parent_profile if parent_profile.save
          end
        end
      end



      #activate season document for given template
      applied_season.notifications.where(:json_template_id => BSON::ObjectId.from_string(params[:form_id])).first.update_attributes(status: 'active')
      session = applied_season.age_group_and_school_days
    else
      # TODO, NEED TO REWORK
      # kid applying for the first time to this org
      # create membership
      kid_org_membership = OrganizationMembership.new(:org_id => @organization.id )
      season.organization_membership.profile = child
      # TODO, create season
      # TODO, Update new attributes of kids if not exist
      #season.save!
    end


    @child_name = Profile.child_name(@parent_profile)
    # Notifier.org_form_submission(child, season_year, session, json.form_name, Time.now, @parent_profile.parent_type.email, @parent_profile.parent_type.fname, @parent_profile.parent_type.lname, @organization.email).deliver
    # Notifier.org_form_submission(child,@parent_profile, parent_type_profiles,applied_season,organization_membership,json.form_name, @organization.email).deliver

    redirect_to org_child_profile_organizations_path(:child => child.kids_type.id, :email =>@parent_profile.parent_type.email )


  end

  private

  def build_nested_form
    @organization = Organization.new
    @organization.weblinks.build

    @season = @organization.seasons.build
    1.times {@season.sessions.build}
  end


  def enrollees_data
    ## Initialize org session, For further use.
    #session[:current_org] = params[:id]
    #
    #@profiles = []
    #
    ## Grab organization details
    #@organization = Organization.where(:_id => session[:current_org]).first
    #
    ## Collect organization season
    #@season_list = organization_seasons @organization
    #
    ## Collect organization specific kids membership
    #@org = OrganizationMembership.where("org_id" => session[:current_org])
    #
    ## Collect all active profile
    #@org_memebership = @org.not_in('seasons.status' => ['inactive'])
    #
    #@org_memebership.each do |member|
    #  member.seasons.each do |season|
    #    if(season.season_year == @season_list.first.split(' (')[0] &&  member.attribute_present?(:profile_kids_type_id))
    #      @profile = Profile.where("kids_type._id" => member.profile_kids_type_id,"kids_type.status" => "active")
    #      @profile.each do |profile_details|
    #        @profiles.push(profile_details)
    #      end
    #    else
    #      # KidProfile fallback
    #      @profile = Profile.where("_id" => member.profile_id)
    #      @profile.each do |profile_details|
    #        @profiles.push(profile_details)
    #      end
    #    end
    #  end
    #end
  end

  def invalid_json_content
    flash[:notice] = "JSON is invalid. Please correct."
    redirect_to :back
  end

=begin
  def load_application_form_status(organization_memberships,org_id,season)
    #all org_memberships are per season and active on based conditions so we can get notifications for this ids
    organization = Organization.find(org_id)
    season = organization.seasons.where(id: season).first
    json_template = organization.json_templates.where(workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form],season_id: season.id).first
    status_hash = {}
    alert_hash = Hash.new { |hash, key| hash[key] = [] }
    if json_template
      notifications = Notification.includes(:organization_membership).in(organization_membership_id: organization_memberships.map(&:id)).where(json_template_id: json_template.id).only(:organization_membership_id,:is_accepted, :season_id)
      alerts = Notification.includes(:organization_membership).in(organization_membership_id: organization_memberships.map(&:id)).requested.alerts
      notifications.each do |notification|
        if notification.belongs_to_season?(season.id)
          status_hash[notification.organization_membership_id] = notification.is_accepted
        end
      end
      alerts.each do |notification|
        org_mem_season = notification.organization_membership.seasons.find_by(season_id: season.org_season_id)
        if notification.season_id.nil?
          # alert is org-wide so user has alerts
          alert_hash[notification.organization_membership.id] << true
        elsif notification.season_id
          #check alert is for selected season or not
          alert_hash[notification.organization_membership.id] << notification.season_id.eql?(org_mem_season.id) ? true : false
        end
      end
    else
      Rails.logger.warn "Application form not found for #{organization.name}'s #{season.season_year}"
    end
    return status_hash ,alert_hash
  end
=end


  def sort_column
    %w(lname_downcase nickname_downcase application_date  age_group_and_school_days).include?(params[:sort]) ? params[:sort] : 'lname_downcase'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def get_enrollees_list(params)
    conditions = {season_status: 'active',org_season_id:  BSON::ObjectId.from_string(session[:season])}
    conditions.merge!({:age_group_and_school_days => session[:session]}) if session[:session].present? and !session[:session].eql?('All')
    conditions.merge!({application_status: session[:enrollement]}) unless session[:enrollement].nil? || session[:enrollement].eql?("All")
    sort_by = {}
    sort_by[sort_column.to_sym] = sort_direction.eql?('desc') ?  -1 : 1
    OrganizationMembership.enrollees_aggregate(params[:org_id],conditions,sort_by)
  end

  #return a hash with key as kid id and values as array of parent emails
  def get_parent_emails(args)
    kids_ids = args.map{|arg|arg['profile_id'].to_s}.uniq.compact
    Hash[Profile.collection.aggregate({"$match"=>{parent_type:{"$exists"=>true},"parent_type.email"=>{"$nin"=>[nil,""]},
                                             "parent_type.profiles_manageds"=>{"$exists"=>true},
                                             "parent_type.profiles_manageds.kids_profile_id"=>{"$in"=>kids_ids}}},
                                 {"$unwind"=>"$parent_type.profiles_manageds"},
                                 {"$project"=>{email_id:"$parent_type.email",
                                               kid_id:"$parent_type.profiles_manageds.kids_profile_id"}},
                                 {"$group"=>{_id:"$kid_id", emails:{"$push"=>"$email_id"}}}).map(&:values)]


  end
end
