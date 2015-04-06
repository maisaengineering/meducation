namespace :db do


  desc "Task for new json dynamic forms"
  task :json_setup => :environment do
    Rake::Task["db:create_application_form"].invoke
    Rake::Task["db:remove_enrollment"].invoke
    Rake::Task["db:move_profile_status"].invoke
    Rake::Task["db:assign_profile_id"].invoke
    Rake::Task["db:add_key_to_phone_numbers"].invoke
    Rake::Task["db:create_application_form_notification"].invoke
    Rake::Task["db:acknowledge_form"].invoke
    #Rake::Task["db:send_photograph_of_child"].invoke
  end

  task :obfuscate_users => :environment do
    Rake::Task["db:obfuscate_users"].invoke
  end




  desc "Create Application Form"
  task :create_application_form => :environment do
    puts "------------------------------------------------------------------"
    organization = Organization.first
    season = organization.seasons.find_by(season_year: '2013-2014')
    puts "      Creating Application Form for '#{organization.preffered_name}' ... "
    json_template = organization.json_templates.build(organization_id: organization.id,category: 'Application Form',form_name: 'Application',form_status: 'active',
                                                      season_id: season.id,workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form])
    json_template.content =  <<EOS
                              {"form":{"name":"Application","season":"2013-2014","panel":[{"name":"Child Information","field":[{"id":"fname","name":"First name","unique":"univ","required":"true"},{"id":"lname","name":"Last name","unique":"univ","required":"true"},{"id":"nickname","name":"Preferred name/nickname","unique":"univ","required":"true"},{"id":"gender","name":"Sex","unique":"univ","type":"select","selection_list":["Male","Female"],"lookup":"sex","required":"true"},{"id":"birthdate","name":"Birthdate","unique":"univ","type":"date","required":"true"},{"id":"food_allergies","name":"Food allergies","unique":"univ","type":"textarea","required":"false"},{"id":"medical_issues","name":"Medical issues","unique":"univ","type":"textarea","required":"false"},{"id":"special_needs","name":"Special needs","unique":"univ","type":"textarea","required":"false"},{"id":"other_concerns","name":"Other concerns","unique":"univ","type":"textarea","required":"false"}]},{"name":"Enrollment","field":[{"id":"family_currently_enrolled","name":"Family currently enrolled?","unique":"seas","type":"select","lookup":"yesno","selection_list":["Yes","No"],"required":"true"},{"id":"active_member_of_ppc","name":"Active members of Peachtree Presbyterian Church?","unique":"seas","type":"select","selection_list":["Yes","No"],"lookup":"yesno","required":"true"},{"id":"age_group_and_school_days","name":"Age group and school days","unique":"seas","type":"select","lookup":"sessions","required":"true"},{"id":"secondary_choice_of_class_days","name":"Secondary choice of class days","unique":"seas","required":"false"},{"id":"are_you_enrolling_siblings","name":"Are you enrolling siblings today?","unique":"seas","type":"select","selection_list":["Yes","No"],"lookup":"yesno","required":"true"},{"id":"sibling_name","name":"Sibling's name","unique":"seas","required":"false"},{"id":"sibling_age","name":"Sibling's age group","unique":"seas","required":"false"},{"id":"sibling_days","name":"Sibling's days","unique":"seas","required":"false"}]},{"name":"Address","field":[{"id":"address1","name":"Address (Line 1)","unique":"univ","required":"true"},{"id":"address2","name":"Address (Line 2)","unique":"univ","required":"false"},{"id":"city","name":"City","unique":"univ","required":"true"},{"id":"state","name":"State","unique":"univ","required":"true"},{"id":"zip","name":"Zip","unique":"univ","required":"true"}]},{"name":"Parents","fieldgroup":{"multiply":"true","multiply_default":2,"multiply_link":"Add Additional Parents","field":[{"id":"child_relationship","name":"Parent relationship","unique":"parent","type":"select","selection_list":["Father","Mother","Step-father","Step-mother","Grandmother","Grandfather","Guardian","Other"],"required":"true"},{"id":"fname","name":"First name","unique":"parent","required":"true"},{"id":"lname","name":"Last name","unique":"parent","required":"true"},{"id":"email","name":"E-mail address","unique":"parent","required":"true"},{"id":"phone1","name":"Phone number #1","unique":"parent","type":"phone","selection_list":["Home","Mobile","Work"],"required":"true"},{"id":"phone2","name":"Phone number #2","unique":"parent","type":"phone","selection_list":["Home","Mobile","Work"],"required":"false"},{"id":"phone3","name":"Phone number #3","unique":"parent","type":"phone","selection_list":["Home","Mobile","Work"],"required":"false"}]}},{"name":"Admission Agreement","field":[{"id":"agreement_1","name":"I understand that to complete this application, I will pay a non-refundable $125 registration fee. I hereby agree to pay the tuition in three equal installments due April 16, 2013, November 1, 2013, and February 3, 2014. I understand that tuition is non-refundable except as outlined in the Preschools limited tuition refund policy stated in the Admissions section of the Preschool website.","unique":"seas","type":"check_box","reverse":"true","required":"true"},{"id":"ack_signature","name":"Signature","unique":"seas","type":"ack"},{"id":"ack_date","name":"Date","unique":"seas","type":"ack"}]}]}}
EOS
    json_template.save!
    puts "-- SUCCESS : Successfully created application form for '#{organization.preffered_name}' -----------------"

  end

  desc "Move membership_enrollments to season top level instead of nested level"
  task :remove_enrollment => :environment do
    puts "------------------------------------------------------------"
    puts   "   Moving membership_enrollments to season top level   ...."
    organization = Organization.first
    memberships = OrganizationMembership.where(org_id: organization.id)
    count = 0
    memberships.each do |membership|
      membership.seasons.each do |season|
        membership_enrollment = season.membership_enrollment
        unless membership_enrollment.nil?
          keys =  membership_enrollment.fields.keys - ["_type", "_id"] # remove default keys
          keys.each do  |key|
            key_as_sym = key.to_sym
            val = membership_enrollment.send(key)
            # Retrieve a dynamic field safely.
            season.read_attribute(key_as_sym)
            # Write a dynamic field safely to season.
            season.write_attribute(key_as_sym, val)
          end
          season.membership_enrollment = nil #delete embed doc if no need
          if season.save!
            season.unset(:status) #default inactive is creating ,so remove and assign this from profile(from below rake task)
            count += 1
          end
        end
      end
    end
    puts "------ SUCCESS : total #{count} membership_enrollment fields moved to season top level --------"
  end


  desc "Move profile 'status' to season "
  task :move_profile_status => :environment do
    puts "------------------------------------------------------------"
    puts   "      Moving profiles status field to season ...          "
    organization = Organization.first
    memberships = OrganizationMembership.where(org_id: organization.id)
    count = 0
    memberships.each do |membership|
      membership.seasons.each do |season|
        if membership.respond_to?(:profile_kids_type_id)
          profile = Profile.where('kids_type._id' => membership.profile_kids_type_id).first
          #if profile has kids_type and the field 'status' exists in kids_type
          if profile and profile.kids_type and profile.kids_type.respond_to?(:status)
            season.read_attribute(:status)  # assign status field to season
            season.write_attribute(:status,  profile.kids_type.status)  # Write a status from profile to season
            if season.save
              profile.kids_type.unset(:status) # remove status attribute from kids_type profile
              count += 1
            end
          end
        end
      end
    end
    puts "-- SUCCESS : total #{count} profile 'status' attribute moved to season -----------------"
  end


  desc "Assign Profile id to profile_kids_type_id in org membership "
  task :assign_profile_id => :environment do
    puts "------------------------------------------------------------"
    puts   "      Assigning profile_id and remove profile_kids_type_id ...          "
    organization = Organization.first
    memberships = OrganizationMembership.where(org_id: organization.id)
    count = 0
    memberships.each do |membership|
      membership.seasons.each do |season|
        if membership.respond_to?(:profile_kids_type_id)
          profile = Profile.where('kids_type._id' => membership.profile_kids_type_id).first
          if profile and profile.kids_type
            membership.profile_id =  profile.id
            if membership.save!
              membership.unset(:profile_kids_type_id) # remove this field
              count += 1
            end
          end
        end
      end
    end
    puts "-- SUCCESS : total #{count} profile_id to assigned to profile_kids_type_id-----------------"
  end

  desc "Add key field to parent phone numbers"
  task :add_key_to_phone_numbers => :environment do
    puts "------------------------------------------------------------"
    puts   "      Adding key to phone numbers...          "
    profiles = Profile.all

    profiles.each do |profile|
      parent_type = profile.parent_type
      if parent_type
        i = 1
        parent_type.phone_numbers.each do |phone_number|
          phone_number['key'] = "phone#{i}"
          i += 1 if phone_number.save
        end
      end
    end
    puts "-- SUCCESS : Added key to phone numbers-----------------"
  end










  desc "Create default notification(Application form) for organization_membership(default application form sumbitted)"
  task :create_application_form_notification => :environment do
    puts "------------------------------------------------------------------"
    puts "      Creating Default Applicatin From notification for each season in membership ... "
    organization = Organization.first
    season = organization.seasons.find_by(season_year: '2013-2014')
    json_template  = organization.json_templates.where(season_id: season.id,workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form]).first # get the application form
    raise "###### ERROR ######: ------  There is no JsonTemplate with workflow 'Application Form'.Feel free to create and run the task again." if json_template.nil?
    memberships = OrganizationMembership.all
    count = 0
    memberships.each do |membership|
      membership.seasons.each do |season|
        profile = Profile.find(membership.profile_id)
        #if profile has kids_type and the field 'status' exists in kids_type
        if profile and profile.kids_type
          #spelling mistake for is_accepted across the application be sure to cross check
          notification = NormalNotification.new(organization_membership_id: membership.id,category: Notification::CATEGORIES[:form],
                                                is_accepted: season.is_acceped,json_template_id: json_template.id,status: 'active',submitted_count: 1)


          season.notifications << notification
          season.unset(:is_acceped) if season.respond_to?(:is_acceped) # remove the attribute from season collection
          count += 1
        end
      end
    end
    puts "-- SUCCESS : total #{count} notifications(Application form) are created newly-----------------"
  end

  desc "Create Acknowledgment for application form notification"
  task :acknowledge_form => :environment do
    puts "------------------------------------------------------------------"
    puts "     Acknowledging application form notification ... "
    organization = Organization.first
    season = organization.seasons.find_by(season_year: '2013-2014')
    json_template  = organization.json_templates.where(season_id: season.id,workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form]).first # get the application form
    memberships = OrganizationMembership.where(org_id: organization.id)
    count = 0
    memberships.each do |membership|
      membership.seasons.each do |season|
        profile = Profile.find(membership.profile_id)
        #if profile has kids_type and the field 'status' exists in kids_type
        if profile and profile.kids_type
          notification = Notification.where(organization_membership_id: membership.id,category: Notification::CATEGORIES[:form],
                                            season_id: season.id,json_template_id: json_template.id).first
          acknowledgment = Acknowledgment.where(acknowledgment_name: 'application',kids_id: profile.id).first
          if notification and acknowledgment and acknowledgment.respond_to?(:user_id)
            notification.update_attributes(user_id: acknowledgment.user_id,acknowledgment_date: acknowledgment.acknowledgment_at)
            count += 1
          else
            puts "INFO: Acknowledgment not found for '#{profile.kids_type.name}' ,ID: #{profile.id} ,kids_linkid: #{profile.kids_type.kids_id}"
          end
        end
      end
    end
    puts "-- SUCCESS : total #{count}/#{memberships.count} notifications(Application form) Acknowledged -----------------"
  end



  desc "Create and send Photo graph of child"
  task :create_photograph_of_child => :environment do
    puts "------------------------------------------------------------------"
    puts "Creating Photograph of child"
    organization = Organization.first
    season = organization.seasons.find_by(season_year: '2013-2014')
    organization.document_definitions.find_or_create_by(season_id: season.id,name: DocumentDefinition::PHOTOGRAPH,workflow: DocumentDefinition::WORKFLOW_TYPES[:auto],is_for_season: true)
    puts "# Done ."
  end

  desc "Create and send Photo graph of child"
  task :send_photograph_of_child => :environment do
    puts "------------------------------------------------------------------"
    puts "Creating and sending photograph of child for active kids"
    organization = Organization.first
    season = organization.seasons.find_by(season_year: '2013-2014')
    memberships =  OrganizationMembership.where("org_id" => organization._id,"seasons.season_year" => '2013-2014').not_in('seasons.status' => 'inactive')
    seas_document_definition = organization.document_definitions.find_or_create_by(season_id: season.id,name: DocumentDefinition::PHOTOGRAPH,workflow: DocumentDefinition::WORKFLOW_TYPES[:auto],is_for_season: true)
    count = 0
    memberships.each do |membership|
      membership.seasons.first.notifications << NormalNotification.create!(organization_membership_id: membership.id,category: Notification::CATEGORIES[:document],is_accepted: 'requested',document_definition_id: seas_document_definition.id)
      count += 1
    end
    puts "-- SUCCESS : total #{count} Photo graph of child document requested-----------------"
  end

  desc "Create weblinks"
  task :create_weblinks => :environment do
    puts "Creating weblinks ...."
    organization = Organization.first
    organization.weblinks.delete_all
    organization.weblinks.create(link_name: 'Calendar',link_url: 'http://www.peachtreepresbyterianpreschool.org/Calendar.aspx')
    organization.weblinks.create(link_name: 'Tuition info',link_url: 'http://www.peachtreepresbyterianpreschool.org/Admissions/Tuition.aspx')
    organization.weblinks.create(link_name: 'Admissions info',link_url: 'http://www.peachtreepresbyterianpreschool.org/Admissions/Default.aspx')
    organization.weblinks.create(link_name: 'Peachtree Presbyterian Church',link_url: 'http://www.peachtreepres.org/')
    puts "#Done Weblinks count: #{organization.weblinks.count}"
  end



  desc "Obfuscating users & profiles "
  task :obfuscate_users => :environment do
    puts "-" * 80
    puts "Obfuscating User(s)..."

    User.all.each do |user|
      begin
        # password => 123456
        user.update_attributes!(:password => "123456", :password_confirmation =>  "123456")
        if user.email == "maisa.engineers@gmail.com" then
          next
        end

        # new email
        old_email = user.email
        user.update_attributes!(:email => user.email.gsub(/@.*$/, "@test.com"))

        # Get the changes for a specific field.
        if user.previous_changes['email']
          puts  "Email Changed From To: #{user.previous_changes['email'] }"
        else
          puts  "Email NOT Changed for : #{old_email}"
        end
      rescue
        user.delete
      end
    end
    puts "Users count = #{User.all.count}"
    puts "-" * 80

    puts "Obfuscating Profile(s)..."
    countP = 0
    Profile.all.each do |profile|
      begin
        old_email=profile.parent_type.email.downcase
        if old_email.blank?
          next
        end

        profile.update_attributes!("parent_type.email" => (old_email.downcase).gsub(/@.*$/, "@test.com"),"parent_type.email_dis" => (old_email.downcase).gsub(/@.*$/, "@test.com")) unless old_email.blank?
        countP+=1
      rescue
        next
      end
    end
    puts "Profiles count = #{countP}"


    puts "#------------Changing org email to maisa.engineers@gmail.com ...."
    Organization.update_all(email: 'maisa.engineers@gmail.com')
    puts "#Done ."
  end

  desc "Obfuscating Transaction Emails "
  task :obfuscate_transactions => :environment do
    puts "------------------------------------------------------------------"
    puts "Obfuscating Transaction Emails ...."
    count = 0
    Transaction.all.each do |transaction|
      if transaction.update_attributes!(email: transaction.email.gsub(/@.*$/, "@test.com"))
        count += 1
      end
    end
    puts "-- SUCCESS : total #{count}/#{Transaction.count}  transaction emails obfuscated -----------------"
  end

  desc "Move profile 'terms' to season "
  task :move_profile_terms => :environment do
    puts "------------------------------------------------------------"
    puts   "      Moving profiles terms field to season ...          "
    organization = Organization.first
    memberships = OrganizationMembership.where(org_id: organization.id)
    count = 0
    memberships.each do |membership|
      membership.seasons.each do |season|
        if membership.respond_to?(:profile_id)
          p"--------------profileid#{membership.profile_id}--"
          profile = Profile.where('_id' => membership.profile_id).first
          p"kidstype-------------",profile.kids_type._id
          #if profile has kids_type and the field 'terms' exists in kids_type
          if profile and profile.kids_type and profile.kids_type.respond_to?(:terms)
            season.read_attribute(:terms)  # assign terms field to season
            season.write_attribute(:terms, true)  # Write a terms from profile to season
            if season.save
              profile.kids_type.unset(:terms) # remove terms attribute from kids_type profile
              count += 1
            end
          end
        end
      end
    end
    puts "-- SUCCESS : total #{count} profile 'terms' attribute moved to season -----------------"
  end


  desc "Create SUper admin"
  task :create_super_admin=> :environment do
    user = User.create! :fname => 'Super Admin', :email => 'superadmin@maisasolutions.com', :password => '123456', :password_confirmation => '123456'
    user.create_role(:super_admin)
  end

end