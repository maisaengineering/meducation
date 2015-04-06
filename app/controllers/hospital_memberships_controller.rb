class HospitalMembershipsController < ApplicationController
  skip_before_filter :authenticate_user!, only: ['new', 'create','kid_form', 'top_hospitals', 'validate_email', 'change_wellness_partner']
  layout 'start_page_layout'

  #def new
  # @hospital_membership = HospitalMembership.new
  #end

  def create
    HospitalMembership.registration(params)
    resource = User.where(email: params[:parents]['0'][:info][:email]).first
    if !resource.blank?
      sign_in(:user, resource)
      redirect_to after_sign_in_path_for(resource)
    else
      redirect_to  root_url
    end
  end

  def kid_form
    render partial: 'kid_form', locals:{index: params[:index]}
  end

  def top_hospitals
    hospitals = Hospital.where(name: session[:partner])
    is_sponsor =  hospitals.map(&:zipcodes).flatten.include?(params[:zipcode])
    hospitals=  Hospital.onboarding(params[:zipcode]) if hospitals.blank?
    uneditable = (hospitals.count==1 and hospitals.first.is_default)
    render partial: 'top_hospitals', locals:{hospitals: hospitals, is_sponsor:  is_sponsor || uneditable}
  end

  def change_wellness_partner
    hospitals = Hospital.onboarding(params[:zipcode], 'all')
    render partial: 'change_wellness_partner', locals:{hospitals: hospitals}
  end

  def validate_email
    profiles=Profile.where(:'parent_type.email'=> params[:email].downcase)
    user = User.where(:email => params[:email].downcase).first
    if user
     user.has_role?(:parent) ? ( render text: 1) : ( render text: 0)
    else
       profiles.empty? ? ( render text: 0) : ( render text: 1)
    end

  end

end
