class Devise::SessionsController < DeviseController
  prepend_before_filter :require_no_authentication, :only => [ :create ]
  prepend_before_filter :allow_params_authentication!, :only => :create
  skip_before_filter :change_url, only: [:new]
  skip_before_filter :verify_authenticity_token, :only => [:destroy]
  layout 'start_page_layout', :only=>['new']

  #caches_page :new, :show, gzip: :best_compression, if: Proc.new { flash.count == 0 }

  # GET /resource/sign_in
  def new
    if current_user
      redirect_to  after_sign_in_path_for(current_user)
    else
      @alert_msg = alert

      resource = build_resource(nil, :unsafe => true)
      clean_up_passwords(resource)
      session[:referral_code] ||= params[:referral_code]
      session[:partner]  ||= params[:partner]
      respond_with(resource, serialize_options(resource))
    end
  end

  # POST /resource/sign_in
  def create
    resource = warden.authenticate!(auth_options)
    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    #session[:access_token]= params[:access_token]
    respond_with resource, :location => after_sign_in_path_for(resource)
  end

  # DELETE /resource/sign_out
  def destroy
    cookies.delete(:visited_start_page)
    session.delete(:access_token)
    redirect_path = after_sign_out_path_for(resource_name)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out

    # We actually need to hardcode this as Rails default responder doesn't
    # support returning empty response on GET request
    respond_to do |format|
      format.mobile{redirect_to root_url}
      format.any(*navigational_formats) { redirect_to redirect_path }
      format.all do
        head :no_content
      end
    end
  end

  protected

  def serialize_options(resource)
    methods = resource_class.authentication_keys.dup
    methods = methods.keys if methods.is_a?(Hash)
    methods << :password if resource.respond_to?(:password)
    { :methods => methods, :only => [:password] }
  end

  def auth_options
    { :scope => resource_name, :recall => "#{controller_path}#new" }
  end
end

