namespace :db do
  desc "To add unsubscribe email feature"
  task add_unsubscribe_emails_field: :environment do
    Profile.where(:parent_type.exists=>true).map(&:save)
  end

#  ====== for dev & testing

end