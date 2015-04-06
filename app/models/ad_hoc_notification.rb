class AdHocNotification  < Notification

  include Mongoid::Attributes::Dynamic
  public_class_method :new

  field :is_accepted , default: 'requested'

  after_create :send_alert_email, unless: proc{|noti| noti.profile.parent_type and noti.profile.parent_type.ae_notification_opt_out }

  def category
    self.ae_definition.category
  end
  private
  # rails4.0 update
  def send_alert_email
    profile = self.profile
    profile_emails = []
    if profile.parent_type  and !profile.parent_type.unsubscribe_emails
      profile_emails = []
      profile_emails << profile.parent_type.email
    elsif profile.kids_type
      profile_emails  = profile.parent_profiles.subscribed_emails.map(&:parent_type).map(&:email)
    end
    profile_emails.each do |email|
      Notifier.delay.ae_alerts(self, email)
    end
  end

end
