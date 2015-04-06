module ApplicationHelper

  def title(page_title)
    content_for :title, "KidsLink"
  end

  def javascript(*files)
    content_for(:head) { javascript_include_tag(*files) }
  end

  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def targetValForField(target, index, type, key)
    #raise target.inspect
    #raise 'dcs'
    if target and target[type.to_sym]
      if (e = target[type.to_sym][index]) and (h = e[key.to_sym])
        case
          when (h_klass=h.class) == Hash
            h unless h.length<=0
          when h_klass == String
            h unless h.eql?"{}"
          else
            h
        end
      end
    end
  end

  def selection_lookup(org, qHash)
    fieldItems = nil
    if org.nil? || qHash.nil?
      return
    end
    begin
      _organization = Organization.find(org)
      case qHash["field"]
        when "sessions"
          _qSeason = qHash["season"]
          _organization.seasons.each do |season|
            next if _qSeason != season["season_id"] unless _qSeason.nil?
            season.sessions.each do |session|
              (fieldItems||=[])<< session.session_name
            end
          end
      end
    rescue Exception => e
      # swallow
    end

    fieldItems
  end

  def comment(&block)
    #block the content
  end

  # forms the link for season document alert
  def link_to_doc_or_form_alert(notification,kid_profile,is_admin)
    content = content_tag :dt do
      notification.document_definition.nil? ? link_to_form_data(notification,kid_profile,is_admin) :
          link_to_document(notification,kid_profile,is_admin)

    end
    #content << content_tag(:dl ,"due by #{notification.due_by}")
  end

  # if notification responds_to json_template_id its a form else document(responds_to document_definition_id)
  def link_to_doc_or_form(notification,kid_profile,is_admin)
    content_tag :tr do
      content = content_tag :td do
        notification.document_definition.nil? ? link_to_form_data(notification,kid_profile,is_admin) :
            link_to_document(notification,kid_profile,is_admin)
      end
      content << content_tag(:td ,notification.created_at.strftime("%m/%d/%y"),class: 'panelUniDocDate')
    end
  end

  #if requested(new) link to 'new document' else 'show' the document existed
  def link_to_document(notification,kid_profile,is_admin)

    if is_admin == true

      unless notification.document.nil?
        url =  colored_document_url(notification.document)
      else
        url = notification.document.attachment.converted_pdf.url rescue nil
      end

      link_to_unless(notification.document.nil? ,notification.document_definition.name ,url,target: '_blank')
    else
      link_to(notification.document_definition.name ,
              notification.document.nil? ? new_document_path(kid_profile.id,notification_id: notification.id) :
                  document_path(kid_profile.id ,notification.document_id))
    end
  end

  def link_to_form_data(notification,kid_profile,is_admin)
    if is_admin
      # except requested(not yet submitted) enable the link
      link_to_unless(notification.is_accepted.eql?('requested'),"#{notification.json_template.form_name}",
                     form_data_organizations_path(child: kid_profile.id, json_template_id: notification.json_template.id,
                                                  org_id: notification.organization.id, season_id: notification.season.org_season_id),target: '_blank')

    else
      link_to("#{notification.json_template.form_name}",
              form_data_profiles_path(profile_id: kid_profile.id, notification_id: notification.id,
                                      org_id: notification.organization.id, season_id: notification.season.org_season_id))

    end

  end

  def avatar(profile,version = :thumb,is_admin = false)
    if profile.photograph and profile.photograph.attachment_processing == false
      is_admin.eql?(true) ? image_tag(profile.photograph.source.thumb.url,:width=>180) : image_tag(profile.photograph.source.url,:width=>70)
    elsif  profile.photograph and profile.photograph.attachment_processing == true
      is_admin.eql?(true) ? image_tag(profile.photograph.source.thumb.url,:width=>180) : image_tag(profile.photograph.source.url,:width=>70 )
    else
      is_admin.eql?(true) ?  image_tag( 'default.png', width: 180) : image_tag( 'default.png', width: 70,height: 99)
    end
  end


  class BraintreeFormBuilder < ActionView::Helpers::FormBuilder
    include ActionView::Helpers::AssetTagHelper
    include ActionView::Helpers::TagHelper

    # http://stackoverflow.com/a/20123990/1591926 changed for rails 4.0 update
    def initialize(object_name, object, template, options)
      super
      @braintree_params = @options[:params]
      @braintree_errors = @options[:errors]
    end

    def fields_for(record_name, *args, &block)
      options = args.extract_options!
      options[:builder] = BraintreeFormBuilder
      options[:params] = @braintree_params && @braintree_params[record_name]
      options[:errors] = @braintree_errors && @braintree_errors.for(record_name)
      new_args = args + [options]
      super record_name, *new_args, &block
    end

    def text_field(method, options = {})
      has_errors = @braintree_errors && @braintree_errors.on(method).any?
      field = super(method, options.merge(:value => determine_value(method)))
      result = content_tag("div", field, :class => has_errors ? "fieldWithErrors" : "")
      result.safe_concat validation_errors(method)
      result
    end

    protected

    def determine_value(method)
      if @braintree_params
        @braintree_params[method]
      else
        nil
      end
    end

    def validation_errors(method)
      if @braintree_errors && @braintree_errors.on(method).any?
        @braintree_errors.on(method).map do |error|
          content_tag("div", ERB::Util.h(error.message), {:style => "color: red;"})
        end.join
      else
        ""
      end
    end
  end


  def org_status_width_and_class(is_accepted)
    display_name,css_class,width = '','' ,''
    case is_accepted
      when 'Application submitted'
        display_name,css_class,width = 'App. submitted','AppSubmitted' ,20
      when 'Accepted'
        display_name,css_class,width = 'Accepted','Accepted' ,50
      when 'Registered'
        display_name,css_class,width = 'Registered','Registered' ,70
      when 'Enrolled'
        display_name,css_class,width = 'Enrolled','Enrolled' ,100
    end
    return display_name,css_class,width
  end
  def more(string, length, separator = nil)
    return '' if !string
    if string.length > (length * 1.2)
      out = content_tag(:span, truncate(string, length: length, separator: separator))
      out += link_to_function('more', "$(this).prev().hide(); $(this).hide(); $(this).next().show();")
      out += content_tag(:span, string, :style => 'display:none')
      out
    else
      string
    end
  end

  def url_with_protocol(url)
    /^http/.match(url) ? url : "http://#{url}"
  end

  def category_icon(category)
    case category.name
      when 'Activities'
        asset_url('d_icon_activities.png')
      when 'Financial'
        asset_url('d_icon_financial.png')
      when 'Health'
        asset_url('d_icon_health.png')
      when 'Household' ,'Family'
        asset_url('d_icon_family.png')
      when 'ID & vital records','Identity'
        asset_url('d_icon_id.png')
      when 'School'
        asset_url('d_icon_school.png')
      else
        #any default image
    end
  end

  def m_category_icon(category)
    case category.name
      when 'Activities'
        asset_path('m_icon_activities.png')
      when 'Financial'
        asset_path('m_icon_financial.png')
      when 'Health'
        asset_path('m_icon_health.png')
      when 'Household' ,'Family'
        asset_path('m_icon_family.png')
      when 'ID & vital records','Identity'
        asset_path('m_icon_id.png')
      when 'School'
        asset_path('m_icon_school.png')
      else
        #any default image
    end
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == sort_column) ? "header_#{sort_direction}" : 'header'
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    #link_to title, {:sort => column, :direction => direction}, {remote: true,:class => "#{css_class}"}
    content_tag(:td,title,class: "#{css_class} enrollees_order_by",:"data-sort"=>column,:"data-direction"=>direction)
  end

  def us_territory_codes
    ["AK", "MT", "AL", "NE (NB)", "AR", "NC", "AZ", "ND", "CA", "NH", "CO", "NJ", "CT", "NM", "CZ", "NY", "DC", "NV", "DE", "OH", "FL", "OK", "GA", "OR", "HI", "PA", "IA", "PR", "ID", "RI", "IL", "SC", "IN", "SD", "KS", "TN", "KY", "TX", "LA", "UT", "MA", "VA", "MD", "VI", "ME", "VT", "MI", "WA", "MN", "WI", "MO", "WV", "MS", "WY"]
  end

  # using 'dotiw' gem: display age only with  years and months(like: 2 years and 2 months,1 year and 1 month , 10 months, 0 months)
  def accurate_humanize_age(date)
    if date < Time.now
      age = remove_unwanted_words distance_of_time_in_words(Time.now, date, false, except: %w(days hours minutes seconds))
      age_month = remove_unwanted_words distance_of_time_in_words(Time.now, date, false, except: %w(hours minutes seconds))
      age.present? ? age.gsub(/ ,/, ', ') : (age_month.present? ? age_month : '0 days')
    else
      "due #{date.strftime("%b #{date.day.ordinalize}, %Y")}"
    end
  end

  def doclist_size
    session[:doc_ids] ?   session[:doc_ids].size   : 0
  end

  def alert_or_event_buttons(profile,notification)
    content = ''
    AeDefinition::REQUEST_BUTTONS.each do |key,value|
      content << content_tag(:div , class: "alertButton ab#{key.to_s.classify}") do
        link_to(value,update_alert_or_event_path(profile,notification,ae_definition_id: notification.ae_definition.id, status: value))
      end if notification.ae_definition.request_buttons.include?(value)
    end
    content.html_safe
  end

  def append_dot(text)
    (text.eql?(nil) or text.strip.eql?('')) ? "" : "&#8226; #{text}".html_safe
  end

  def alert_or_event_buttons_at_topdashboard(profile,notification)
    content = ''
    AeDefinition::REQUEST_BUTTONS.each do |key,value|
      content << content_tag(:div , class: "alertButton ab#{key.to_s.classify}", onClick: "window.location.href='#{update_alert_or_event_path(profile,notification,ae_definition_id: notification.ae_definition.id, status: value)}';") do
        link_to(value, '#')
      end if notification.ae_definition.request_buttons.include?(value)
    end
    content.html_safe
  end


  def fb_feed_url(redirect_uri, feed_params={})
    app_id = ENV['FB_APP_ID']
    options = {text: 'Share',name:'',display:'',caption: '',description: '',link: '',picture: '',source: '',properties: {},actions: {}}.merge!(feed_params)
    opts_array = []
    feed_params.each do |key, value|
      case
        when key.to_s == 'properties'
          @prop = value.to_json
        when key.to_s == 'actions'
          @action = value.to_json
        else
          opts_array.push("#{key}=#{value}")
      end
    end
    "http://www.facebook.com/dialog/feed?app_id=#{app_id}&redirect_uri=#{redirect_uri}&#{opts_array.join("&")}&properties=#{@prop}&actions=#{@action}"
  end

  # header photo
  def mini_photo(document)
    if  document and !document.source_tmp.nil?
      image_tag("#{root_url}uploads/tmp/#{document.source_tmp}", width: 70)
    elsif  document
      image_tag(document.source.mini.url)
    else
      image_tag(asset_path('d_defaultavatar.png'))
    end
  end

  #def mini_photo_background(document)
  #  if document and !document.source.mini.file.length.nil?
  #    "background-image:url(#{document.source.mini.url})"
  #  elsif  document
  #    "background-image:url(#{document.source.url})"
  #  else
  #    "background-image:url(#{asset_path('d_defaultavatar.png')})"
  #  end
  #end

  def thumb_photo_background(document)
    if  document and document.attachment_processing == false
      "background-image:url(#{document.source.thumb.url})"
    elsif  document
      "background-image:url(#{document.source.url})"
    else
      "background-image:url(#{asset_url('d_defaultavatar_large.png')})"
    end
  end

  def thumb_photo(document)
    if  document and document.attachment_processing == false
      image_tag(document.source.thumb.url)
    elsif  document
      image_tag(document.source.url)
    else
      image_tag(asset_path('d_defaultavatar_large.png'))
    end
  end

  def pre_fills(object, attribute)
    unless object.nil?
      object.pre_fill(attribute)
    end
  end

  def append_line_break(str)
    (str.eql?(nil) or str.strip.eql?('')) ? str : "#{str} <br/>".html_safe
  end

  def append_parentheses(str)
    (str.eql?(nil) or str.strip.eql?('')) ? str : "(#{str})".html_safe
  end

  # removing "and" word in age
  def remove_unwanted_words string
    bad_words = ["and", "about"]
    bad_words.each do |bad|
      string.gsub!(bad, ',')
    end
    return string
  end

  def ios_version
    ios_version = request.user_agent.match(/OS (\d+)_(\d+)_?(\d+)?/)
    return ios_version[1].to_i
  end
  # display kid name if and only the alert/event belongs to specific kid and not to other(siblings) and not to parent
  def show_kid_name_on_alert?(managed_kid_ids,notifications,current_profile,ae_definition,n_profile)
    #notifications.where(:profile_id.ne=>current_profile.id,:profile_id.in=>@managed_kids.map(&:id),ae_definition_id: ae_definition.id).count(true).eql?(1) if current_profile.parent_type and ae_definition.to_whom.eql?('kid')
    #Use Set for large arrays - http://stackoverflow.com/questions/8026300/check-for-multiple-items-in-array-using-include-ruby-beginner
    values = (managed_kid_ids.push(current_profile.id)-[n_profile.id]).map{|k| [ae_definition.id, k]}.to_set
    !notifications.any? { |x| values.include?(x) } if current_profile.parent_type and ae_definition.to_whom.eql?('kid')
  end

  # render organization/application layout for SuperaAdmin/OrgAdmin ,for parent its parent_layout
  def role_based_preferences_path
    begin
      role_names.include?(:parent) ? preferences_path(@parent_profile || current_user.parent_profile) : edit_user_registration_path(current_user._id)
    rescue
      edit_user_registration_path(current_user._id)
    end
  end


  def registration_logo_path
    req_params = {kidslink_network_id: params[:kidslink_network_id],org_id: params[:org_id],season_year: params[:season_year], season_id: params[:season_id]}
    if user_signed_in?
      if current_page?(controller: 'payments',action: 'new')
        '#'
      elsif current_page?(controller: 'profiles',action:  'new_logged_in') or current_page?(controller: 'profiles',action:  'edit_existing')
        profile_request_organizations_path(req_params)
      else
        user_dashboard_path #top_dashboard_path(current_user.parent_profile)
      end
    elsif current_page?(controller: '/organizations',action: 'profile_request') or current_page?(controller: '/profiles',action: 'new') or current_page?(controller: 'devise/registrations',action: 'new')
      profile_request_organizations_path(req_params)
    else
      root_path
    end
  end


end
