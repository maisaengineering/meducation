namespace :db do
  desc "Remove Normal form sent to Withdrawn kids"
  task clean_withdrawn_notifications: :environment do
    json_template_ids = ENV['TemplateIds'].split()
    # Get all Withdrawn memberships
    withdrawn_mebs = Notification.where(is_accepted: 'Withdrawn').map(&:organization_membership_id)
    normal_notifications = Notification.where(:organization_membership_id.in=> withdrawn_mebs,:json_template_id.in=>json_template_ids)
    count = normal_notifications.delete_all
    puts "****Info: Found total #{withdrawn_mebs.count} withdrawn memberships and deleted total Normal forms for those are #{count}"
  end
end