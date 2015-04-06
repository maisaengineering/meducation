class PaymentsController < ApplicationController
  skip_before_filter :authenticate_user!
  def new
    user = current_user.nil? ? User.where(id: params[:resource_id]).first : current_user
   # user.parent_profile.make_as_creator(params[:profile_id])
    @organization = Organization.find(params[:org_id])
    @amount = calculate_amount
    session[:registration_data] = { profile_id: params[:profile_id],org_id: params[:org_id],season_id: params[:season_id],
                                    session: params[:session],resource_id: params[:resource_id],notification_id: params[:notification_id]  }
    @kidslink_price = 0
    organization_fee = @amount
    @total_price = organization_fee.to_i+@kidslink_price
    #render :layout => "application_form_layout"
  end

  def update_discount_price
    @coupon = Admin::Coupon.where(organization_id: params[:org_id], name: params[:coupon_code]).first
    organization_fee = params[:amount].to_f + 0.0
    kidslink_price = ( params[:annual_fee].to_f + 0.0)

    if @coupon
      deal_price = @coupon.try(:discount).to_f / 100
    else
      deal_price = 0.0
    end
    @discounted_price = ((organization_fee + kidslink_price) * deal_price).round
    @amount = (organization_fee+kidslink_price) - @discounted_price

    respond_to do |format|
      format.js {}
    end
  end

  def confirm
    user = current_user.nil? ? User.where(id: session[:registration_data][:resource_id]).first : current_user
    @result = Braintree::TransparentRedirect.confirm(request.query_string)
    Rails.logger.info @result.inspect
    if @result.success?
      Transaction.create(:transaction_id => @result.transaction.id, :type => @result.transaction.type, :status => @result.transaction.status,
                         :amount => @result.transaction.amount, :lname => @result.transaction.customer_details.last_name, :fname => @result.transaction.customer_details.first_name,
                         :email => user.email, :address =>@result.transaction.billing_details.street_address, :city =>@result.transaction.billing_details.locality,
                         :state =>@result.transaction.billing_details.region, :zip => @result.transaction.billing_details.postal_code,
                         :coupon => @result.transaction.order_id,organization_id: session[:registration_data][:org_id],season_id: session[:registration_data][:season_id],user_id: user.id,profile_id: BSON::ObjectId.from_string(session[:registration_data][:profile_id]))

      unless session[:existing_child]
        user.update_attribute(:active, true)
        sign_in user
      else
        Rails.logger.info current_user.inspect
        user.update_attribute(:active, true)
      end
      flash[:notice] ='Thanks for kidslink payment.'
      kid_profile = Profile.where(id: BSON::ObjectId.from_string(session[:registration_data][:profile_id])).first
      #payment
      user.acknowledgments.create!(season: session[:registration_data][:season_id], org_id: session[:registration_data][:org_id], kids_id: session[:registration_data][:profile_id],
                                   user_name: user.fname , acknowledgment_name: 'payment', acknowledgment_at: Time.now)

      organization =  Organization.find(session[:registration_data][:org_id])

      #@profile = Profile.where('_id' => BSON::ObjectId.from_string(params[:kid_id])).first


      org_membership = kid_profile.organization_membership(organization.id)
      #raise @organization.inspect
      # Fallback if nil OrganizationMembership
      # @org_memebership = OrganizationMembership.where("org_id" => params[:org_id],"profile_kids_type_id" => @kid_profile.kids_type.id).first if @org_memebership.blank?


      season_year = organization.seasons.where(id: session[:registration_data][:season_id]).first.season_year
      # Grab applied season
      applied_season = org_membership.applied_season(session[:registration_data][:season_id])
      # Update Profile is active to season
      applied_season.update_attribute(:status, 'active')

      #update application form notification(to grab Acknowledgment details) with user_id and acknowledgment_date
      notification = Notification.find(session[:registration_data][:notification_id])
      notification.update_attributes(user_id: user.id,acknowledgment_date: notification.created_at)
      web_link_url= organization.weblinks.blank? ? nil : organization.weblinks[0].link_url
      parent_profiles = kid_profile.parent_profiles.subscribed_org_emails
      parent_profiles.each do |each_parent|
        unless each_parent.parent_type.email.blank?
          if(each_parent.parent_type.email!= user.email)
            #@all_data = Profile.where("parent_type.email" => each_parent.parent_type.email)
            all_data = User.where(email: each_parent.parent_type.email)
            Notifier.application_confirmation(each_parent.parent_type.email, kid_profile.kids_type.fname, organization.name,season_year, session[:registration_data][:session],web_link_url, kid_profile.kids_type.nickname).deliver
            if(all_data.count > 0)
              Notifier.signup_additional_confirmation_for_existing(kid_profile.kids_type.fname, user.fname, user.lname, each_parent.parent_type.email, kid_profile.kids_type.nickname).deliver
            else
              new_pwd = Profile.generate_activation_code
              Notifier.signup_additional_confirmation(kid_profile.kids_type.fname, user.fname, user.lname, new_pwd,each_parent.parent_type.email, kid_profile.kids_type.nickname).deliver
              new_user = User.create!(:email=>each_parent.parent_type.email, :fname => each_parent.parent_type.fname, :lname => each_parent.parent_type.lname,:password => new_pwd, :password_confirmation => new_pwd)
              new_user.create_role(:parent)
            end
          end
        end
      end
      session.delete(:error_mes)
      Notifier.application_confirmation(user.email, kid_profile.kids_type.fname, organization.name, season_year, session[:registration_data][:session], web_link_url,kid_profile.kids_type.nickname).deliver
      Notifier.signup_confirmation(user.email,kid_profile.kids_type.fname,@result.transaction.customer_details.email, @result.transaction.amount, kid_profile.kids_type.lname, kid_profile.kids_type.nickname).deliver
      Notifier.org_application(organization.email,season_year, session[:registration_data][:session],kid_profile.kids_type.fname,kid_profile.kids_type.nickname,kid_profile.kids_type.lname, Time.now, organization.id, kid_profile.kids_type.id.to_s).deliver
      # clear all session of registration data here---------
      session.delete(:registration_data)
      redirect_to profiles_path(profile_id: kid_profile.id,org_id: organization.id,season_id: applied_season.org_season_id,season_year: season_year)
    else
      session.delete(:error_mes)
      @result.errors.each do |error|
        # session[:error_mes] += error.code
        session[:error_mes] = session[:error_mes].to_s + " " + error.message.to_s
      end
      redirect_to :back
    end
  end

  protected

  def calculate_amount
    # in a real app this be calculated from a shopping cart, determined by the product, etc.
    # Organization fee should be dynamic, it will come from Organization collection field "org_fee"
    season = @organization.seasons.where(id: params[:season_id]).first
    if season.respond_to?(:season_fee)
      season.season_fee
    else
      nil
    end
  end
end
