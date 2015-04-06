namespace :db do
  desc "Remove Previous user tags array"
    task remove_user_tags: :environment do
      Profile.where(:user_tags.exists=>true).each{|pro| pro.unset(:user_tags)}
    end
  end