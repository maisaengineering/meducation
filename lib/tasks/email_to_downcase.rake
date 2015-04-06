namespace :db do
  desc " Converts Emails to down case"
  task emails_to_downcase: :environment do
    profiles =Profile.where(:parent_type.exists=> true).reject{|p| p.parent_type.email.match(/[A-Z]/).nil?}
    puts profiles.map(&:parent_type).map(&:email).map(&:downcase)
    profiles.map(&:save)
    puts "Above #{profiles.count} emails converted to downcase"
  end
end