class AlertsAndEventsController < ApplicationController
  layout 'parent_layout'
  before_filter :find_profile #, :find_hospital_and_memberships

  #before_filter :find_memberships

  # For family get all kids requested valid notifications ; For kid get only requested valid notifications of him/her
  def index
    @notifications = notifications_vault
  end

  # update notification status(is_accepted) i.e; ihave_done/ignored/thanks
  def update_status
    if @kid_profile
      notification = Notification.find(params[:notification_id])
      notification.update_attributes(:is_accepted=>params[:status])
    else # from parent profile
      # update all notifications of manged kids who has common ae_definition(alert/event) from parent view(dashboard or vault)
      notifications = Notification.any_of({profile_id: @parent_profile.id}, {parent_id: @parent_profile.id}).and(ae_definition_id: params[:ae_definition_id])
      notifications.each do |noti|
        noti.update_attributes(:is_accepted=>params[:status])
      end
    end
    if request.xhr?
      render nothing: true
    else
      redirect_to alerts_and_events_path(params[:profile_id])
    end
  end

  def show
    @notification = Notification.find(params[:notification_id])
  end

end

