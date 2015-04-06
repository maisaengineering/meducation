class Devise::PasswordsController < DeviseController
  prepend_before_filter :require_no_authentication
  skip_before_filter :redirect_https


  layout :layout_by_resource

  def layout_by_resource
    if mobile_devices_format?
      "start_page_layout"
    else
      "application"
    end
  end

  # GET /resource/password/new
  def new
    build_resource({})
  end

  # POST /resource/password
  #def create
  #  self.resource = resource_class.send_reset_password_instructions(resource_params)
  #
  #  if successfully_sent?(resource)
  #    respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
  #  else
  #    unless mobile_devices_format?
  #      respond_with(resource)
  #    else
  #      redirect_to :back, :notice => 'Invalid email'
  #    end
  #  end
  #end
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)

    if successfully_sent?(resource)
      unless mobile_devices_format?
        redirect_to :back
      else
        respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
      end
      #redirect_to :back
      #respond_with({}, :location => after_sending_reset_password_instructions_path_for(resource_name))
    else
      unless mobile_devices_format?
        redirect_to :back, :alert => "error"
      else
        redirect_to :back, :notice => 'Invalid email'
      end
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  def edit
    self.resource = resource_class.new
    resource.reset_password_token = params[:reset_password_token]
  end

  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    if resource.errors.empty?
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message(:notice, flash_message) if is_navigational_format?
      #sign_in(resource_name, resource)

      unless mobile_devices_format?
        respond_with resource, :location => root_url
      else
        redirect_to reset_password_success_path
      end
    else
      unless mobile_devices_format?
        respond_with resource
      else
        resource.errors.full_messages.each do |msg|
          @error_msg = msg
        end
        redirect_to :back, :notice => @error_msg
      end
    end
  end

  def forget_password_success

  end

  def reset_password_success

  end

  protected

    # The path used after sending reset password instructions
    def after_sending_reset_password_instructions_path_for(resource_name)
      unless mobile_devices_format?
        new_session_path(resource_name)
      else
        forget_password_success_path(resource_name)
      end
    end

end
