class Admin::TasksController < ApplicationController
  layout 'organization'
  # only superadmin can manage this controller( without model )
  authorize_resource class: false

  def edit_email; end

  def update_email
    user = User.find_by(email: params[:old_email])
    if user.nil? # check if user exists
      flash.now[:error] = "No user exists with the given email(#{params[:old_email]})"
      render 'edit_email' and return
    elsif  params[:old_email].eql?(params[:new_email]) # check if both new and old emails same or not
      flash.now[:error] = 'Old and New emails are same'
      render 'edit_email' and return
    elsif User.where(email: params[:new_email]).exists?  # check if user exists with new email or not, if yes prompt with error
      flash.now[:error] = "User already exists for new email(#{params[:new_email]}),please contact support team."
      render 'edit_email' and return
    elsif Profile.where(:'parent_type.email'=>params[:new_email]).exists?
      flash.now[:error] = "User profile already exists for new email(#{params[:new_email]}),please contact support team."
      render 'edit_email' and return
    else
      begin
        # update single attribute(skip validations/callbacks and updated_at to be update)
        #TODO use Transaction mechanism for below( rollback all if atleast one fails )
        profile = user.parent_profile
        profile.parent_type.set(email: params[:new_email]) if profile
        user.set(email: params[:new_email]) if profile
        Transaction.where(email: user.email).update_all(email: params[:new_email])
        ActivityLog.where(user: user.email).update_all(user: params[:new_email])
        redirect_to admin_edit_email_url,notice: 'Email updated successfully.'
      rescue
        flash.now[:error] = 'Something went wrong please contact support team.'
        render 'edit_email' and return
      end
    end
  end


  def search_parents
    if params[:query].present?
      @name = params[:query].split(" ").map(&:strip)
      query = case @name.count
                when 1
                  {"$and"=>[{:parent_type.exists=>true},
                            {"$or"=>[{:'parent_type.fname'=>/^#{Regexp.escape(@name[0].to_s)}/i},
                                     {:'parent_type.lname'=>/^#{Regexp.escape(@name[0].to_s)}/i},
                                     {:'parent_type.email'=>/^#{Regexp.escape(@name[0].to_s)}/i}]}]}
                when 2
                  {:parent_type.exists=>true,
                   :'parent_type.fname'=>/^#{Regexp.escape(@name[0].to_s)}/i,
                   :'parent_type.lname'=>/^#{Regexp.escape(@name[1].to_s)}/i }
                when 3
                  {:parent_type.exists=>true,
                   :'parent_type.fname'=>/^#{Regexp.escape(@name[0].to_s)}/i,
                   :'parent_type.mname'=>/^#{Regexp.escape(@name[1].to_s)}/i,
                   :'parent_type.lname'=>/^#{Regexp.escape(@name[2].to_s)}/i }
                else
                  {:parent_type.exists=>true}
              end

      @parents = Profile.where(query).asc(:'parent_type.lname', :'parent_type.fname').limit(200)

    end
  end

  def edit_phone_numbers
    @parent_type =  Profile.where("parent_type.email"=>params[:email]).first.parent_type
  end

  def update_phone_numbers
    @parent_type =  Profile.where("parent_type.email"=>params[:email]).first.parent_type
    if @parent_type.update_attributes(params[:profile_parent_type])
      redirect_to admin_search_parents_url,notice: "Phone numbers updated successfully for '#{@parent_type.fname} #{@parent_type.lname}'"
    else
      flash.now[:error] = @parent_type.errors.full_messages.to_sentence
      render 'edit_phone_numbers'
    end
  end



  def edit_user_data
    @profile =  Profile.find_by("parent_type.email"=>params[:email])
  end

  def update_user_data
    @profile = Profile.find(params[:id])
    if @profile
      old ={verified_phone_number: @profile.verified_phone_number, zipcode: @profile.address.zipcode,
            email_subscription: @profile.parent_type.ae_notification_opt_out}

      params[:profile][:parent_type][:ae_notification_opt_out] = params[:profile][:parent_type][:ae_notification_opt_out].eql?("true")
      @profile.update_attributes(params[:profile].merge(:from=>current_user.roles.map(&:name)))
      errors = []
      errors.push(@profile.errors.full_messages) if  @profile.errors.any?

      new = {verified_phone_number: @profile.verified_phone_number, zipcode: @profile.address.zipcode,
             email_subscription: @profile.parent_type.ae_notification_opt_out, hospital_id: hm.hospital_id}

      Rails.logger.info "**************** User data Update Log ****************"
      Rails.logger.info "superadmin(#{current_user.id}) updated user(#{@profile.parent_type.email}) data "
      Rails.logger.info "Old: #{old} "
      Rails.logger.info "new: #{new} "
      Rails.logger.info "**************** End of User data Update Log ****************"

      if errors.flatten.blank?
        render nothing: true, status:200
      else
        render text: errors.flatten.join('\n'), status:400
      end
    else
      render text:"Profile not found", status:400
    end
  end

  def global_settings
    @organization = Organization.unscoped.where(type: "global").first
  end

  def update_settings
    @organization = Organization.unscoped.where(type: "global").first
    @organization.update_attributes(params["kl_config"])
  end

end