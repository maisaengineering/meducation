class DashboardController < ApplicationController

  layout 'parent_layout'

  skip_before_filter :authenticate_user!, only: [:evaluate_name]
  before_filter  :find_profile, except: [:evaluate_password, :evaluate_name]
 # before_filter :find_hospital_and_memberships, except: [:evaluate_password, :evaluate_name]
  before_filter :find_memberships, except: [:evaluate_password, :evaluate_name]
  before_filter  :find_documents, only: [:index, :child_dashboard]
  before_filter :find_notifications,only: [:index, :child_dashboard]


  def index
    # @feed_entries = @parent_profile.trending.map(&:feed_entries).flatten.sort{|x, y | y.published <=> x.published }.first(3)
  end

  # def trending
  #   @feed_entries =@parent_profile.trending.map(&:feed_entries).flatten.sort{|x, y | y.published <=> x.published }.first(20)
  # end

  def child_dashboard
  end

  def child_profile
  end

  def child_profile_edit
    render layout:false
  end

  def update_child_profile
    params[:parents].merge!(:current_user=> @parent_profile)
    @kid_profile.update_attributes(kid: params[:kid], address_params: params[:address], parents: params[:parents])
    if @parent_profile.address
      @parent_profile.address.update_attributes(params[:address])
    else
      @parent_profile.create_address(params[:address])
    end

    @kid_profile.add_changes(@parent_profile.address.previous_changes)
    @kid_profile.add_changed_fields(@kid_profile.kl_changes)
    redirect_to child_profile_path(@kid_profile)
  end

  #======== Ajax calls================
  #----- from document_vault tabs -------------------------
  def document_vault_tabs
    @category_name = params[:category_name]
    render layout: false
  end

  def invite_mom
    @invitation= @parent_profile.friend_invitations.unscoped.find_or_initialize_by(email: params['email'], status: Invitation::STATUS[:invited])
    @invitation.expire_at = 7.days.from_now unless @invitation.new_record?
    @invitation.save unless @invitation.now_sharing
  end

 #comment: no need to find any filters------
  def add_more_parents
    render partial: 'form_parent_info', locals:{f: nil, index:params[:index], relationship:nil, manageable:false}
 end

  #def opting_partner_branding
  #  if params["checked"].eql?("true")
  #    HospitalMembership.deleted.in(profile_id: @parent_profile.id).map(&:restore)
  #  else
  #    @parent_profile.hospital_memberships.flatten.map(&:destroy)
  #  end
  #  render nothing:true
  #end

  def preferences
  end

  def evaluate_password
    if  current_user.valid_password?(params[:password])
      render text: 1
    else
      render text: 0
    end
  end

  def evaluate_name
    profile =nil
    params[:kids].each do |key, value|
      profile=Profile.where("kids_type.fname"=>value[:fname], "kids_type.lname"=>value[:lname]).first
      break if profile
    end

    unless profile
      render text: 1, status:200
    else
      render text: 0, status:406
    end
  end

  private
  def find_documents
    @documents = @kid_profile ? documents_vault.recent : Document.includes(:profile).family(@parent_profile.self_and_shared_docs+@managed_kids.map(&:id)).single.recent
  end

  def find_notifications
    @notifications = notifications_vault
  end

end
