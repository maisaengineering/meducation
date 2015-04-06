namespace :db do
  desc "Remove Duplicate Notifications"
  task remove_duplicate_notifications: :environment do
    puts ''
    puts '       ***--- Please Wait.... this task may takes some time to finish ---***      '
    puts ''
    notifications = Notification.desc(:created_at)
    count = 0
    notifications.each do |notification|
      scope = Notification.where(organization_membership_id: notification.organization_membership_id).requested.asc(:created_at)
      scope = scope.where(json_template_id: notification.json_template_id) if notification.json_template
      scope = scope.where(document_definition_id: notification.document_definition_id) if notification.document_definition
      scope = scope.where(season_id: notification.season_id) unless notification.season_id.nil?
      # if count of notifications are greater than 1 (2 or more) then except this notification remove remaining
      if scope.count > 1
        count += scope.where(:id.ne=> notification.id).delete_all
      end
    end
    puts " ***Info: total #{count} duplicate notifications are deleted permanently "
    puts ''
  end
end