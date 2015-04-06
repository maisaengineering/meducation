namespace :db do
  desc "Integrity check for profiles"
  task integrity_check_profiles: :environment do
    puts "---------------- checking --------------"
    puts "Checking user emails with parent profile"
    profile_emails= Profile.all.collect do |profile|
                      profile.parent_type.email.downcase if profile.parent_type? and profile.parent_type.respond_to?(:email)
                    end

    users_notIn = User.where(:email.nin=> profile_emails)
    users_notIn.each do |profiles_n|
      puts "###################", profiles_n.email
    end

    puts "###### Users without parent profiles", users_notIn.count
    puts "################### Total Users", User.count

    count = 0
    Profile.all.each do |profile|
       count += 1 if profile.parent_type?
    end
    puts "###### Total parent profiles", "#{count}/#{Profile.count}"
  end


  task parent_profiles_with_kids: :environment do
    puts "---------------- checking --------------"
    puts "Checking parent profiles with kids"

    Profile.all.each do |profile|
      profile_parent= profile.parent_type
      kid_ids = profile.parent_type.profiles_manageds.map(&:kids_profile_id)  rescue nil

      @parent_type_id = []
      @second_parent = []
      @second_parent_id = []

      if !kid_ids.nil?
        kid_ids.each do |kid_id|
          @parent_profile = Profile.where("parent_type.profiles_manageds.kids_profile_id" => kid_id)
          p_profile = @parent_profile.where(:_id.nin=> [profile._id]) if !@parent_profile.nil?
          p_profile.each do |par_profile|
            @second_parent << par_profile.parent_type.fname
            @second_parent_id << par_profile.parent_type._id
            @parent_type_id << par_profile.parent_type._id
          end
        end
      end
      parent_ids = @parent_type_id.uniq

      if parent_ids.count > 1
      puts "######### parent ###########", profile_parent.email if profile.parent_type.respond_to?(:email)
      puts "######### kids ###########", kid_ids unless kid_ids.nil?
      puts "########## kids count", kid_ids.count unless kid_ids.nil?
      puts "########## second_parent_names", @second_parent
      #puts "########## second_parent_profile_id", @second_parent_id
      puts "###### second_parent_type_ids", parent_ids
      puts "-" * 40
      puts "-" * 40
      end
    end
  end
end