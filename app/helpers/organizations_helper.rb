module OrganizationsHelper

  def organization_seasons(org)
    seasons_name = org.seasons.collect{|season| season.is_current.eql?(1) ? season.season_year.concat(' (current)') : season.season_year}
    seasons_name.each { |season_year| if season_year.include?('current')
                                        seasons_name.delete_at(seasons_name.index(season_year))
                                        seasons_name.insert(0, season_year)
                                      end unless season_year.nil? }
    return seasons_name
  end

  def dob_con(dob)
    #begin
    #  raise "Nil DOB" if dob.nil?
    #  dob = dob.class == Time ? dob.to_date : Date.parse(dob)
    #rescue Exception => e
    #  Rails.logger.warn "Invalid DOB field: #{e}"
    #end
    if dob.class == Time
      dob = dob.strftime("%m/%d/%Y")
    else
      dob = dob
    end
  end
  def self.splite_dob(kids_dob)
    dob = kids_dob.split('/')
    birthdate = dob[2]+'-'+dob[0]+'-'+dob[1]
    return birthdate
  end
  def get_season_id(year,org_id)
    @org = Organization.where(:_id => org_id).first
    @org.seasons.each do |each_season|
      if each_season.season_year == year
        return each_season._id
      end
    end unless @org.nil?
  end


  def membeship_data(season)
    season.membership_enrollment.nil? ?
        removed_att(season.attributes) :
        removed_att(season.membership_enrollment.attributes)
  end

  def removed_att(hash)
    return hash.delete_if do |k, v|
      ['is_accepted', 'is_current', '_id', 'created_at', 'updated_at'].include? k
    end
  end

  def organization_content(org, form_id)
    @organization = Organization.where(:_id => org.id).first
    @organization.seasons.each do |each_season|
      if(each_season._id == BSON::ObjectId.from_string(params[:season]))
        each_season.json_templates.each do |each_form|
          if(each_form.id.to_s == form_id )
            @form = JSON.parse(each_form.content)
            raise @form.inspect
          end
        end
      end
    end

    return @form
  end
  def organization_sessions(org)
    @current_season = self.organization_seasons org
    @all_season = ['All']
    org.seasons.each do |each_season|
      # session of year compared before with '(current)', now omitted.
      each_season.season_year.include?('current') ?  season = each_season.season_year.split.first : season = each_season.season_year
      if season == session[:season]
        each_season.sessions.each do |each_session|
          @all_season.push(each_session.session_name)
        end
      end
    end
    return @all_season
  end
  def organization_sessions_all(org)
    @current_season = self.organization_seasons org
    @all_season=[]
    org.seasons.each do |each_season|
      # session of year compared before with '(current)', now omitted.
      each_season.season_year.include?('current') ? season = each_season.season_year.split.first : season = each_season.season_year
      if season == session[:season]
        each_season.sessions.each do |each_session|
          @all_season.push(each_session.session_name)
        end
      end
    end
    return @all_season
  end
  # to get dynamic sessions in org enrollee page
  def organization_session(org,session)
    fieldItems = []
    org.seasons.each do |season|
      next if session != season["season_year"] unless session.nil?
      season.sessions.each do |session|
        (fieldItems||=[]) << session.session_name
      end
    end
    return fieldItems
  end
  def organization_sessions_change(org)
    @current_season = self.organization_seasons org
    # raise @current_season.inspect
    @all_season = []
    org.seasons.each do |each_season|
      if each_season.season_year == @current_season.first
        each_season.sessions.each do |each_session|
          @all_season.push(each_session.session_name)
        end
      end
    end
    return @all_season
  end


  def kid_season(org_id, season_id, kid)
    # raise params.inspect
    @org_member = OrganizationMembership.where(:org_id => org_id,"profile_kids_type_id" => kid.kids_type.id).any_of("seasons.org_season_id" => BSON::ObjectId.from_string(season_id)).first
    # OrganizationMembership fallback
    @org_member = OrganizationMembership.where(:org_id => org_id,"profile_id" => kid.id).any_of("seasons.org_season_id" => BSON::ObjectId.from_string(season_id)).first if @org_member.blank?
    if @org_member.nil?
      return
    end

    @season = @org_member.seasons.detect {|season| season.org_season_id == BSON::ObjectId.from_string(season_id)}
    return @season
  end

  def kid_session_by_season(season)
    return nil if season.nil?
    _stored_season_age_grp_school_days =  season.membership_enrollment.age_group_and_school_days if season[:membership_enrollment] and season[:membership_enrollment]["age_group_and_school_days"]
    # back off
    _stored_season_age_grp_school_days = season["age_group_and_school_days"] if _stored_season_age_grp_school_days.nil? or _stored_season_age_grp_school_days.empty?
    return _stored_season_age_grp_school_days
  end
  def kid_session(kid_profile, season)
    @org_member = OrganizationMembership.where(:org_id => session[:current_org],"profile_kids_type_id" => kid_profile.kids_type.id).any_of("seasons.org_season_id" =>BSON::ObjectId.from_string(season)).first
    # OrganizationMembership fallback
    @org_member = OrganizationMembership.where(:org_id => session[:current_org],"profile_id" => kid_profile.id).any_of("seasons.org_season_id" => BSON::ObjectId.from_string(season)).first if @org_member.nil?
    if @org_member.nil?
      return
    end

    @org_member.seasons.each do |each_season|
      if each_season.org_season_id == BSON::ObjectId.from_string(season)
        _stored_season_age_grp_school_days =  each_season.membership_enrollment.age_group_and_school_days if each_season[:membership_enrollment] and each_season[:membership_enrollment]["age_group_and_school_days"]
        # back off
        _stored_season_age_grp_school_days = each_season["age_group_and_school_days"] if _stored_season_age_grp_school_days.nil? or _stored_season_age_grp_school_days.empty?

        return _stored_season_age_grp_school_days
      end
    end
  end

  def kid_status_by_season(season)
    return season.application_form_status if season
  end

  def kid_status(kid_profile, season)
    @org_member = OrganizationMembership.where(:org_id => session[:current_org],"profile_kids_type_id" => kid_profile.kids_type.id).first
    # OrganizationMembership fallback
    @org_member = OrganizationMembership.where(:org_id => session[:current_org],"profile_id" => kid_profile.id).first if @org_member.nil?
    if @org_member.nil?
      return nil
    end

    @org_member.seasons.each do |each_season|
      if each_season.org_season_id == BSON::ObjectId.from_string(season)
        return each_season.application_form_status
      end
    end

    return nil
  end


  def kid_alerts_by_season(season)
    if season
      #check org-wide
      return "Alerts Outstanding" if season.organization_membership.notifications.only(:is_accepted,:season_id,:notification_type).org_wide.alerts.requested.exists?
      #check season-wide
      return "Alerts Outstanding" if season.notifications.only(:is_accepted,:notification_type).alerts.requested.exists?
    end
    return "No alerts"
  end
  def kid_alerts(kid_id, season)
    @org_member = OrganizationMembership.where(:org_id => session[:current_org],"profile_kids_type_id" => kid_id).first
    # null check
    if @org_member.nil?
      return
    end

    count = 0
    @org_member.seasons.each do |each_season|
      if each_season.org_season_id == BSON::ObjectId.from_string(season)
        each_season.json_templates.each do |each_form|
          if(each_form.form_status=="0")
            return "Alerts Outstanding"
          end
        end
      end
    end

    return "No alerts"
  end

  def is_form_exist(season_id)
    @organization = Organization.where(:_id => session[:current_org],"seasons._id" => BSON::ObjectId.from_string(season_id)).first
    @organization.seasons.each do |each_season|
      if each_season._id == BSON::ObjectId.from_string(season_id)
        raise each_season.json_templates.inspect
      end
    end
  end

  def session_applied_count(organization,season_id,session_name)
    OrganizationMembership.where(org_id: organization._id,"seasons.status"=>'active',"seasons.org_season_id"=> BSON::ObjectId.from_string(season_id),"seasons.age_group_and_school_days"=> session_name).count
  end

  def session_accepted_count(organization,season_id,session_name)
    mp_ids = OrganizationMembership.where(org_id: organization._id,"seasons.status"=>'active',"seasons.org_season_id"=> BSON::ObjectId.from_string(season_id),"seasons.age_group_and_school_days"=> session_name).map(&:id)
    season = organization.seasons.where(_id: BSON::ObjectId.from_string(season_id)).first
    application_form = JsonTemplate.where(organization_id: organization.id,season_id: season.id  ,workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form]).first
    return 0 if application_form.nil? || season.nil?
    Notification.any_of({ is_accepted: 'Accepted' },{ is_accepted: 'Registered' },{is_accepted: 'Enrolled'}).where(:organization_membership_id.in=>mp_ids,json_template_id: application_form.id).count
  end

  def org_season_session
    @organization = Organization.where(:_id => session[:org_id]).first
    @session_data=[]
    @organization.seasons.each do |season|
      if(season._id==BSON::ObjectId.from_string(session[:season_id]))
        season.sessions.each do |sessions|
          @session_data.push(sessions.session_name)
        end
      end
    end
    return @session_data
  end

  def application_count(form_id, org_id, season_id)
    return OrganizationMembership.where(:org_id => org_id,'seasons.org_season_id' => BSON::ObjectId.from_string(season_id)).active.count
  end
  #this helper methods moved to json_template as instance methods
=begin

  def sent_forms(form_id, org_id, season_year)
    @org_mem = OrganizationMembership.where(:org_id => org_id,'seasons.season_year' => season_year)
    count = 0
    @org_mem.each do |each_org|
      each_org.seasons.each do |each_season|
          each_season.notifications.alerts.requested.each do |each_form|
            count = count+1 if (each_form.json_template_id == form_id)
        end
      end
    end
    return count
  end

  def accepted_forms(form_id, org_id, season_year)
    @org_mem = OrganizationMembership.where(:org_id => org_id,'seasons.season_year' => season_year)
    count = 0
    @org_mem.each do |each_org|
      each_org.seasons.each do |each_season|
          each_season.notifications.alerts.submitted.each do |each_form|
            count = count+1 if (each_form.json_template_id == form_id)
        end
      end
    end
    return count
  end
=end

  def season_status
    season_st = []
    @organization = Organization.where(:_id => session[:current_org]).first
    @organization.seasons.each do |each_seasons|
      season_st << each_seasons.is_current
    end
    return season_st
  end

  def form_details(season = nil)
    organization = Organization.find(session[:current_org])
    params[:season] = season || params[:season] || session[:season] || organization.seasons.first._id
    #return json templates  with normal workflow for the given season
    org_season = organization.seasons.where(_id: params[:season]).only(:id).first
    normal_templates  = organization.json_templates.where(season_id: org_season.id,:workflow.ne=>JsonTemplate::WORKFLOW_TYPES[:appl_form]).asc(:form_name)
    normal_documents = organization.document_definitions.org_wide + org_season.document_definitions
    normal_documents = normal_documents.sort_by &:name
    options = "<option></option>"
    normal_templates.each{ |t| options << "<option value='form_#{t.id}'>#{t.form_name}</option>" }
    options << "<option>-----</option>"
    normal_documents.uniq.each{|d| options << "<option value='doc_#{d.id}'>#{d.name}</option>"}
    options.html_safe
  end

  def split_array(lookup)
    lookup.split(",")
  end


end
