class RemindAlert< Struct.new(:notification_id)
  def perform
    notification = Notification.where(id: notification_id).first
    profile = notification.profile
    profile_emails = profile.parent_type ? profile.parent_type.email.to_a : profile.parent_profiles.subscribed_ae_emails.map(&:parent_type).map(&:email)
    profile_emails.each do |email|
      Notifier.ae_alerts(notification, email).deliver
    end
    notification.update_attribute(:is_accepted, "requested")
  end
end