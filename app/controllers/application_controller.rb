class ApplicationController < ActionController::Base
  protect_from_forgery
  has_mobile_fu
  before_filter :change_url
  before_filter :authenticate_user!
  before_filter :redirect_https
  before_filter :role_names, :if => proc {|c| current_user }
  helper_method :documents_vault, :notifications_vault, :bucket_phone_numbers_with_label ,
                :kl_data_points ,:absolute_image_url, :register_handlebars, :colored_document_url, :bw_document_url,
                :thumb_document_url ,:user_dashboard_path, :role_names

  rescue_from Exception, with: :render_500 if Rails.env.production?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to user_dashboard_path, alert: t(:access_denied) #exception.message
  end

  def render_500(exception)
    Rails.logger.info "******** Exception *************"
    Rails.logger.info exception
    Rails.logger.info exception.backtrace.join("\n")
    Rails.logger.info "******** end Exception *************"
    respond_to do |format|
      format.html { render template: 'errors/internal_server_error', layout: 'layouts/application', status: 500 }
      format.mobile { render template: 'errors/internal_server_error', layout: 'layouts/error_layout', status: 500 }
      format.all { render nothing: true, status: 500}
    end
    # Immediately send an email to dev team about the exception details
    #ExceptionNotifier.notify_exception(exception,env: request.env, data: {message: 'was doing something wrong'})
  end

  #### public instance Methods goes here ####---------------------------------------------------------------------------
  def after_sign_in_path_for(resource_or_scope)
    unless mobile_devices_format?
      if params[:apply_existing].present? and params[:apply_existing].eql?('yes')
        profile_path(:id => current_user.id, season_id: params[:season_id],org_id: params[:org_id])
      else
        user_dashboard_path
      end
    else
      if current_user and current_user.has_role?(:parent)
        m_top_dashboard_path(current_user.parent_profile)
      elsif current_user
        m_invalid_parent_error_path
      else
        root_url
      end
    end
  end



  def set_mobile_format
    ((is_mobile_device? && !is_device?('iphone')) || is_device?('android'))? request.format = :mobile : :html
  end

  def mobile_devices_format?
    (is_mobile_device? && !is_device?('iphone')) || is_device?('android')
  end


  def set_request_format
    if mobile_devices_format? # this method is provided by mobile_fu
      # when user registering via invitation(SMS) link
      if params[:body].present? and params[:body].include?(:referral_code)
        request.format = :json
      elsif (devise_controller? && action_name == 'create' && request.method == ('POST'))
        request.format = :html
      else
        request.format = :mobile
      end
    end
  end

  def change_url(url = "/m")
    if ((is_mobile_device? && !is_device?('iphone')) || is_device?('android')) and !request.original_url.include?('/m') and signed_in? and !params[:controller].include?("devise") and !params[:controller].include?("omniauth")
      redirect_to root_url
    end
  end

  def find_profile
    @profile = current_user.self_and_managed_kids_profiles.and(id:params["profile_id"]).first
    unless @profile
      redirect_to root_url, alert: t(:access_denied)
      return
    else
      @kid_profile = @profile if @profile.kids_type
      @parent_profile = @profile if @profile.parent_type
      @parent_profile ||= current_user.parent_profile
      @managed_kids = @parent_profile.managed_kids
    end
  end

  # def find_hospital_and_memberships
  #   @hospital_memberships = @parent_profile ? @parent_profile.hospital_memberships  : HospitalMembership.in(profile_id: @parent_profile.id) rescue []
  #   @hospital = @hospital_memberships.first.hospital rescue nil
  # end

  def find_current_user_profile
    @current_user_profile = Profile.where("parent_type.email"=>current_user.email).first
  end

  def find_memberships
    #for left child dashboard(to show list of enrolled org memberships)
    @organization_memberships = @kid_profile.organization_memberships if @kid_profile
  end

  def redirect_https
    if Rails.env.production?
      redirect_to :protocol => "https://" unless request.ssl?
    end
    true
  end

  def stored_location_for(resource_or_scope)
    nil
  end

  def role_names
    @roles ||= current_user.roles.only(&:name).map(&:name).map(&:parameterize).map(&:underscore).map(&:to_sym)
  end

  #### Both Helper and Instance Methods ####----------------------------------------------------------------------------
  # a common helper to find user dashboard(home) based on role
  def user_dashboard_path
    role_names
    if  @roles.count > 1
      if  @roles.include?(:parent)
        launch_profiles_path(profile_id: current_user.parent_profile)
      else
        launch_profiles_path(user_id: current_user.id)
      end
    elsif  @roles.include?(:parent)
      top_dashboard_path(current_user.parent_profile)
    elsif  @roles.include?(:super_admin)
      organizations_path
    elsif  @roles.include?(:org_admin)
      if current_user.managed_organizations.count > 1
        launch_profiles_path(user_id: current_user.id)
      else
        org_enrollees_organizations_path(:id => current_user.managed_organizations.first.id,clear_session: true)
      end
    else
      root_path
    end
  end

  def documents_vault(category=nil)
    if category.is_a?(Category)
      category_names =  category.children.blank? ? category.name : (category.root? ? category.leaves.only(:name).map(&:name)+ user_tags_at(category) : category.leaves.only(:name).map(&:name))
      documents= @kid_profile ? @kid_profile.documents.without(:attachment, :source).single.tagged_with_any(category_names) : Document.includes(:profile).without(:attachment, :source).family(@parent_profile.self_and_shared_docs).single.tagged_with_any(category_names)
      documents.reject{|document| category.leaf? and !document.tags_array.last.eql?(category_names)}
    elsif category.is_a?(UserTag)
      documents= @kid_profile ? @kid_profile.documents.without(:attachment, :source).single.tagged_with_any(category.tag) : Document.includes(:profile).without(:attachment, :source).family(@parent_profile.self_and_shared_docs).single.tagged_with_any(category.tag)
    else
      @kid_profile ? @kid_profile.documents.single : Document.includes(:profile).family(@parent_profile.self_and_shared_docs).single
    end
  end

  def user_tags_at(category)
    @parent_profile.user_tags.only(:tag).in(category_ids: category.id.to_s).map(&:tag)
  end


  def notifications_vault
    @notifications = @kid_profile ? @kid_profile.notifications.and(parent_id:@parent_profile.id).includes(:profile,:ae_definition).requested.desc(:updated_at) : Notification.includes(:profile,:ae_definition).any_of({profile_id: @parent_profile.id},{parent_id: @parent_profile.id}).requested.desc(:updated_at)
  end




  #Rails default is @milestone.milestone_image=># /uploads/milestone/milestone_image/5225b197c1bb1b0468000008/passport.jpg
  #To get with host use below i.e; http://localhost:3000/uploads/milestone/milestone_image/5225b197c1bb1b0468000008/passport.jpg
  def absolute_image_url(url)
    "#{request.protocol}#{request.host_with_port}#{url}"
  end


  def register_handlebars
    @handlebars = Handlebars::Context.new
    @handlebars.register_helper(:ifEqual) do |context, v1,v2, block|
      if v1===v2
        block.fn(context)
      else
        block.inverse(context)
      end
    end
  end

  def colored_document_url(document)
    if document.photo_graph?
      document.source.url
    elsif document.attachment_processing == false
      document.extension_is?(:pdf) ? document.attachment.url : document.attachment.converted_pdf.url
    elsif document.attachment_processing == true
      if mobile_devices_format?
        m_full_view_path(document.profile_id, document)
      else
        full_view_document_path(document.profile_id, document, format: :pdf)
      end
    else
      #nothing to show
    end
  end

  def bw_document_url(document)
    if document.photo_graph?
      document.source.url
    elsif document.attachment_processing == false
      #document.extension_is?(:pdf) ? document.attachment.bw_pdf.url :  document.attachment.converted_bw_pdf.url
      document.extension_is?(:pdf) ? document.attachment.url :  document.attachment.converted_pdf.url
    elsif document.attachment_processing == true
      if mobile_devices_format?
        m_bw_view_path(document.profile_id, document)
      else
        bw_view_document_path(document.profile_id, document, format: :pdf)
      end
    else
      #nothing to show
    end
  end

  def thumb_document_url(document)
    if document.photo_graph?
      if document.source and document.attachment_processing == false
        document.source.thumb.url
      elsif document.source
        document.source.url
      end
    else
      if document.attachment_processing == false
        document.attachment.thumb.url
      else
        document.attachment.url
      end
    end
  end

  # def is_iphone_browser?
  #   user_agent =  request.env['HTTP_USER_AGENT'].downcase
  #   user_agent.index('iphone') and user_agent.include?("safari") and !user_agent.include?("crios")
  # end

  def trackUserDefinedTags
    if params[:document].include?(:tags)
      tags = params[:document][:tags].split(',')
      tags.map(&:strip!)
      tags.uniq.each do |tag|
        user_tag= @parent_profile.user_tags.where(tag: tag).first ||@parent_profile.user_tags.create(tag: tag, category_ids: params[:document][:category_id].to_a)
        if !user_tag.nil? and !user_tag.category_ids.include?(params[:document][:category_id])
          begin
            user_tag.update_attributes(category_ids: user_tag.category_ids.push(params[:document][:category_id]))
          rescue
            next
          end
        end
      end
    end
  end
  ##  Dynamic JSON FORM Related Stuff

  #TODO need to modify this method
  def parsedFromJSON(json, kid_profile, parents, season, organization_membership)
    error_kid = Hash.new
    parent_profile_type = nil
    JSON.parse(json.content)['form']['panel'].each do |t_panel|
      if !t_panel['field'].nil?
        t_panel['field'].each do |t_field|
          error_kid[t_field['unique']] ||= Array.new
          @f_val = params['profile'][t_field['unique']][0].fetch(t_field['id'], nil)
          @dyna_field = t_field['id'].to_sym
          t_nq = t_field['unique']
          t_nq ||= "seas" ## defaults to season

          # required + req variant validations
          case t_field['required']
            when "true"
              error_kid[t_field['unique']].push(t_field['id']) if @f_val.blank?
            when "trueif"
              f_status = Profile.check_required_if(t_field['required_if'],t_field['id'],t_nq,params['profile'],@f_val, 0)
              error_kid[t_field['unique']].push(t_field['id']) if f_status
            else
          end
          # DATE type validation(s)
          #if t_field['type'] == "date"
          #  error_kid[t_nq].push(t_field['id']) unless @f_val =~ Profile::DOB_REGX
          #end
          #if t_field['id']== "birthdate"
          #  error_kid[t_nq].push(t_field['id']) unless Profile.check_birth_date(@f_val)
          #end
          if t_field['type'] == "date" or t_field['id']== "birthdate"
            error_kid[t_nq].push(t_field['id']) unless Profile.check_birth_date?(@f_val)
          end
          # load to right bucket
          case t_field['unique']
            when "univ"
              #kid_profile.read_attribute(@dyna_field.to_sym)
              kid_profile.write_attribute(@dyna_field.to_sym, @f_val)
              # create or update phone numbers if and only the type is 'phone'
              create_or_update_phone_numbers(t_field['type'], kid_profile, @dyna_field, @f_val)
            when "org"
              #organization_membership.read_attribute(@dyna_field.to_sym)
              organization_membership.write_attribute(@dyna_field.to_sym, @f_val)
              # create or update phone numbers if and only the type is 'phone'
              create_or_update_phone_numbers(t_field['type'], organization_membership, @dyna_field, @f_val)
            when "seas"
              #season.read_attribute(@dyna_field.to_sym)
              season.write_attribute(@dyna_field.to_sym, @f_val)
              # create or update phone numbers if and only the type is 'phone'
              create_or_update_phone_numbers(t_field['type'], season, @dyna_field, @f_val)
              if t_field['type'].eql?('check_box')
                if @f_val == "0"
                  season[@dyna_field.to_sym] = false
                elsif @f_val == "1"
                  season[@dyna_field.to_sym] = true
                end
              end
            when "parent"
              parent_profile_type||= ProfileParentType.new()
              parent_profile_type[@dyna_field] = @f_val
          end

        end
        # if parent observed part of field declaration, just add
        if parent_profile_type
          parents.push(parent_profile_type)
          parent_profile_type = nil
        end
      elsif !t_panel['fieldgroup'].nil? and !t_panel['fieldgroup']['field'].nil?
        # check group fields uniqueness
        t_nq_arr = t_panel['fieldgroup']['field'].collect { |item| item['unique'] }.uniq
        raise "FieldGroup's all fields should have same type" if t_nq_arr.nil? or t_nq_arr.size != 1
        t_nq = t_nq_arr.first
        parents_count = 0 # parent pointer
        error_kid[t_nq] ||= Array.new
        params['profile'][t_nq].each do |f_field|
          f_field.last.each { |key, val|
            error_kid[t_nq][parents_count] ||= Hash.new
            # Find params attribute from template json
            t_att = t_panel['fieldgroup']['field'].detect { |each_field| each_field['id'] == key }
            #----------For First parent------------------
            if parents_count.eql?(0)
              validate_field_group_fields(t_att,error_kid,t_nq,parents_count,val)
            else
              ##----- Except First parent: remove phone hash and check if all the values are empty or not(ex: email,fname,lname,child_relationship),if at least one is non-empty then apply below
              validate_field_group_fields(t_att,error_kid,t_nq,parents_count,val) unless f_field.last.values.delete_if{ |e| e.is_a?(Hash)}.all?{|v| v.blank? }
            end

            unless error_kid[t_nq][parents_count].has_key?(t_att['id'])
              # just create, if not initialized
              parent_profile_type||= ProfileParentType.new()

              # handl ephone with care :)
              if t_att['type'].eql?('phone')
                parent_profile_type.phone_numbers.push(PhoneNumber.new(contact: val['contact'], type: val['type'], key: key)) # unless val['contact'].blank? or val['type'].blank?
              else
                parent_profile_type[key.to_sym] = val
              end
            else
              # dont worry. field added to errors hash
            end
          }
          # add parent
          if parent_profile_type
            #parent_profile_type.email = parent_profile_type.email.downcase
            parents.push(parent_profile_type)
            parent_profile_type = nil
          end
          parents_count += 1
        end
      end
    end
    error_kid.delete_if { |k, v| v.instance_of?(Array) and v.length < 1 }
    return kid_profile, parents, season, organization_membership, error_kid
  end

  def store_validations(profile)
    @storedDataHash = {}
    @storedDataHash[:univ], @storedDataHash[:seas], @storedDataHash[:org], @storedDataHash[:parent] = [], [], [], []
    @storedDataHash[:univ][0], @storedDataHash[:seas][0], @storedDataHash[:org][0] = {}, {}, {}

    profile.each do |each_data|
      case each_data[0]
        when "univ", "org", "seas"
          each_data[1][0].each do |val|
            @storedDataHash[each_data[0].to_sym][0][val[0].to_sym] = val[1]
          end
        when "parent"
          each_data[1].each_with_index do |parent, index|
            @storedDataHash[:parent][index] = {}
            parent.last.each do |val|
              @storedDataHash[:parent][index][val[0].to_sym] = val[1]
            end
          end
        else
          p "Invalid data type, #{each_data[0]}."
      end
    end
    session[:params_value] = @storedDataHash
  end

  def create_or_update_phone_numbers(field_type, bucket_object, dyna_field, f_val)
    # create phone numbers if and only of is 'phone'
    if field_type.eql?('phone')
      phone_exists = bucket_object.phone_numbers.where(key: dyna_field).first
      phone_exists.delete if phone_exists #if object is persisted then delete,no worry below its again initializes
      bucket_object.phone_numbers.push(PhoneNumber.new(key: dyna_field.to_sym, contact: f_val['contact'], type: f_val['type'])).uniq
      bucket_object.unset(dyna_field.to_sym) # no need to save them into bucket so remove
    end
  end

  def validate_field_group_fields(t_att,error_kid,t_nq,parents_count,val)
    unless t_att['required'].nil?
      if t_att['required'].eql?('true')
        # check required value
        error_kid[t_nq][parents_count][t_att['id']]=nil if val.blank?
        if t_att['type'].eql?('phone')
          error_kid[t_nq][parents_count][t_att['id']]=nil if val['contact'].blank? and val['type'].blank?
        end
        if t_att['id'].eql?('email') and !val.blank?
          error_kid[t_nq][parents_count][t_att['id']]=nil unless (val =~ Profile::EMAIL_REGX)
        end
      elsif t_att['required'].eql?('trueif')
        if t_att['id'].eql?('email') and !val.blank?
          error_kid[t_nq][parents_count][t_att['id']]=nil unless (val =~ Profile::EMAIL_REGX)
        end
        s_status = Profile.check_required_if(t_att['required_if'],t_att['id'],t_att['unique'],params['profile'],val,parents_count)
        error_kid[t_nq][parents_count][t_att['id']]=nil if s_status
      end
    end
  end

  # Getting phone_numbers and label for given bucket from specified template
  def bucket_phone_numbers_with_label(bucket_object, bucket, json_template)
    phone_numbers = {}
    bucket_object.phone_numbers.each do |phone_number|
      # grab phone number from specified bucket under given template
      label_of_phone = json_template.label_name(bucket, phone_number.key.to_s)
      if label_of_phone
        p_type = phone_number.type.blank? ? nil : "(#{phone_number.type})"
        phone_numbers[label_of_phone] = "#{phone_number.contact} #{p_type}"
      end
    end unless bucket_object.phone_numbers.blank?
    return phone_numbers
  end

 # declare methods as private or protected below and assign them above this
 # private :method1, :method2, :method3
 # protected :method1, :method2, :method3

end
