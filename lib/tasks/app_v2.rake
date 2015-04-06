namespace :db  do

  desc "adding organisation season id to organization membership"
  task :add_org_season_id => :environment do
    count=0
    OrganizationMembership.all.each do |org_member|
      org=Organization.find(org_member.org_id)
      org_member.seasons.each do |org_member_season|
        season= org.seasons.where(:season_year=>org_member_season.season_year).first
        if !season.nil? and !org_member_season.season_year.nil? and org_member_season.org_season_id.nil?
          org_member_season.update_attributes(:org_season_id=>season.id)
          count +=1
        end
        org_member_season.unset('season_year') unless org_member_season.season_year.nil?
      end
    end
    puts  "#{count} records updated..........."
  end

  desc "Adding profile_id to previous notification at production data using organization membership id."
  task add_profile_id_to_notification: :environment do
    notifications = Notification.where(profile_id: nil)
    notifications =  notifications.reject{|n| !n.organization_membership?}
    count =0
    notifications.each do |n|
      n.update_attributes(:profile_id=> n.organization_membership.profile.id)  rescue  count +=1
    end
    puts "#{notifications.count-count}/#{notifications.count} records Sucessfully upadated."
  end


  desc "Copying Zipcode to profile from ProfilekidsType."
  task copy_zipcodes: :environment do
    Profile.all.map(&:save)
    puts "Successfully Done."
  end

  desc "adding multi_upload"
  task :add_multi_upload => :environment do
    Document.update_all(multi_upload: false, tags_array: [Document::PHOTOGRAPH])
    Document.all.unset(:names)
    puts "Successfully Done."
  end

  desc "adding manageable field to parent_type profiles managed "
  task :add_manageable_field => :environment do
    Profile.where(:parent_type.exists=> true).each do |profile|
      profile.parent_type.profiles_manageds.update_all(manageable: true)
    end

  end

  desc "Creating Categories"
  task create_categories: :environment do

    Category.destroy_all
    Category.create(name: 'Quick captures', position:0)
    health = Category.create(name: 'Health', position:3)
    household = Category.create(name: 'Household', position:4)
    id_and_vital_cards = Category.create(name: 'ID & vital records', position:5)
    activities = Category.create(name: 'Activities', position:1)
    financial = Category.create(name: 'Financial', position:2)
    school = Category.create(name: 'School', position:6)

    #1)Activities ======================================================================================================
    activities.children.create(name: "Achievement (#{activities.name.downcase})")
    activities.children.create(name: "Contract (#{activities.name.downcase})")
    activities.children.create(name: "Directory (#{activities.name.downcase})")
    activities.children.create(name: "Handbook (#{activities.name.downcase})")
    activities.children.create(name: "ID card (#{activities.name.downcase})")
    activities.children.create(name: "Instructions (#{activities.name.downcase})")
    activities.children.create(name: "Invoice (#{activities.name.downcase})")
    activities.children.create(name: "List (#{activities.name.downcase})")
    activities.children.create(name: "Receipt (#{activities.name.downcase})")
    activities.children.create(name: "Registration form (#{activities.name.downcase})")

    activities.children.create(name: "Contact info (#{activities.name.downcase})", align_side: true)
    activities.children.create(name: "Certificate (#{activities.name.downcase})", align_side: true)
    activities.children.create(name: "Estimate (#{activities.name.downcase})", align_side: true)

    #2)Financial =======================================================================================================
    auto_insurance_info = financial.children.create(name: 'Auto insurance info')
    auto_insurance_info.children.create(name: 'Auto insurance info')
    auto_insurance_info.children.create(name: 'Auto insurance card')
    auto_insurance_info.children.create(name: 'Auto insurance documentation')
    contract =   financial.children.create(name: "Contract")
    contract.children.create(name: "Contract")
    contract.children.create(name: "Contract (#{activities.name.downcase})")
    contract.children.create(name: "Contract (#{household.name.downcase})")
    contract.children.create(name: "Contract (#{health.name.downcase})")
    contract.children.create(name: "Contract (#{school.name.downcase})")
    contract.children.create(name: "Household help contract")
    contract.children.create(name: "Nanny contract")
    financial.children.create(name: 'Coupon')
    estimate = financial.children.create(name: "Estimate")
    estimate.children.create(name: "Estimate")
    estimate.children.create(name: "Estimate (#{activities.name.downcase})")
    estimate.children.create(name: "Estimate (#{household.name.downcase})")
    estimate.children.create(name: "Estimate (#{health.name.downcase})")
    estimate.children.create(name: "Estimate (#{school.name.downcase})")
    health_insurance_info = financial.children.create(name: 'Health insurance info')
    health_insurance_info.children.create(name: 'Health insurance info')
    health_insurance_info.children.create(name: 'Health insurance card')
    health_insurance_info.children.create(name: 'Health insurance documentation')
    financial.children.create(name: "Instructions (#{financial.name.downcase})")
    invoice = financial.children.create(name: 'Invoice')
    invoice.children.create(name: 'Invoice')
    invoice.children.create(name: "Invoice (#{activities.name.downcase})")
    invoice.children.create(name: "Invoice (#{household.name.downcase})")
    invoice.children.create(name: "Invoice (#{health.name.downcase})")
    invoice.children.create(name: "Invoice (#{id_and_vital_cards.name})")
    invoice.children.create(name: "Invoice (#{school.name.downcase})")
    list = financial.children.create(name: 'List')
    list.children.create(name: 'List')
    list.children.create(name: "List (#{financial.name.downcase})")
    list.children.create(name: 'Grocery list')
    list.children.create(name: 'Shopping list')
    list.children.create(name: 'Maintenance list')
    receipt = financial.children.create(name: "Receipt")
    receipt.children.create(name: "Receipt")
    receipt.children.create(name: "Receipt (#{activities.name.downcase})")
    receipt.children.create(name: "Receipt (#{household.name.downcase})")
    receipt.children.create(name: "Receipt (#{health.name.downcase})")
    receipt.children.create(name: "Receipt (#{school.name.downcase})")
    financial.children.create(name: 'Warranty')

    financial.children.create(name: "Contact info (#{financial.name.downcase})", align_side: true)
    financial.children.create(name: 'Life insurance documentation', align_side: true)

    #3) Health =========================================================================================================
    health.children.create(name: 'Allergy details')
    health.children.create(name: "Doctor's notes")
    health.children.create(name: 'Finger/footprints')
    health_insurance_info = health.children.create(name: 'Health insurance info')
    health_insurance_info.children.create(name: 'Health insurance info')
    health_insurance_info.children.create(name: 'Health insurance card')
    health_insurance_info.children.create(name: 'Health insurance documentation')
    health_record = health.children.create(name: 'Health record')
    health_record.children.create(name: 'Health record')
    health_record.children.create(name: 'Dental record')
    health_record.children.create(name: 'Medical record')
    health_record.children.create(name: 'Physical record')
    health.children.create(name: "Invoice (#{health.name.downcase})")
    health.children.create(name: "List (#{health.name.downcase})")
    health.children.create(name: "Medication details")
    health.children.create(name: "Receipt (#{health.name.downcase})")

    health.children.create(name: 'Birth certificate', align_side: true)
    health.children.create(name: "Contact info (#{health.name.downcase})", align_side: true)
    health.children.create(name: "Contract (#{health.name.downcase})", align_side: true)
    health.children.create(name: "Estimate (#{health.name.downcase})", align_side: true)
    health.children.create(name: "ID card (#{health.name.downcase})", align_side: true)
    health.children.create(name: "Instructions ", align_side: true)

    #4)House Hold ======================================================================================================    household.children.create(name: "Contact info (#{household.name.downcase})")
    contract = household.children.create(name: "Contract")
    contract.children.create(name: "Contract")
    contract.children.create(name: "Contract (#{household.name.downcase})")
    contract.children.create(name: "Household help contract")
    contract.children.create(name: "Nanny contract")
    household.children.create(name: "Estimate (#{household.name.downcase})")
    greeting = household.children.create(name: "Greeting card")
    greeting.children.create(name: "Greeting card")
    greeting.children.create(name: "Birthday card")
    greeting.children.create(name: "Get-well-soon card")
    greeting.children.create(name: "Holiday card")
    greeting.children.create(name: "Sympathy card")
    greeting.children.create(name: "Thank-you card")

    instructions = household.children.create(name: "Instructions")
    instructions.children.create(name: "Instructions")
    instructions.children.create(name: "Babysitter instructions")
    instructions.children.create(name: "Care instructions (#{health.name.downcase})") # resides in both health and household
    instructions.children.create(name: "Dietary instructions")
    instructions.children.create(name: "Feeding instructions")
    instructions.children.create(name: "Household help instructions")
    instructions.children.create(name: "Instructions (#{household.name.downcase})")
    instructions.children.create(name: "Nanny instructions")

    household.children.create(name: 'Invitation (event)')
    household.children.create(name: "Invoice (#{household.name.downcase})")
    list = household.children.create(name: 'List')
    list.children.create(name: 'List')
    list.children.create(name: 'Chores list')
    list.children.create(name: 'Gift list')
    list.children.create(name: 'Grocery list')
    list.children.create(name: 'Maintenance list')
    list.children.create(name: 'Party list')
    list.children.create(name: 'Shopping list')
    list.children.create(name: 'Travel packing list')
    household.children.create(name: "Receipt (#{household.name.downcase})")
    certificate = household.children.create(name: 'Certificate')
    certificate.children.create(name: 'Certificate')
    certificate.children.create(name: 'Baptism certificate')
    certificate.children.create(name: "Certificate (#{household.name.downcase})")
    certificate.children.create(name: 'Communion certificate')

    household.children.create(name: 'Recipe', align_side: true)

    #5)ID & Vital cards ================================================================================================
    id_and_vital_cards.children.create(name: 'Birth certificate')
    certificate = id_and_vital_cards.children.create(name: 'Certificate')
    certificate.children.create(name: 'Certificate')
    certificate.children.create(name: 'Baptism certificate')
    id_and_vital_cards.children.create(name: "Driver's license")
    id_card = id_and_vital_cards.children.create(name: "ID card")
    id_card.children.create(name: "ID card")
    id_card.children.create(name: "ID card (#{health.name.downcase})")
    id_card.children.create(name: "ID card (#{school.name.downcase})")
    id_card.children.create(name: "ID card (#{activities.name.downcase})")
    id_card.children.create(name: 'State ID card')
    id_and_vital_cards.children.create(name: Document::PHOTOGRAPH)
    id_and_vital_cards.children.create(name: 'Passport')
    id_and_vital_cards.children.create(name: 'Finger/footprints')
    id_and_vital_cards.children.create(name: 'Proof of citizenship')
    id_and_vital_cards.children.create(name: 'Proof of residency')

    id_and_vital_cards.children.create(name: "Instructions (#{id_and_vital_cards.name})", align_side: true)
    id_and_vital_cards.children.create(name: "Invoice (#{id_and_vital_cards.name})", align_side: true)
    id_and_vital_cards.children.create(name: 'List', align_side: true)
    id_and_vital_cards.children.create(name: "Receipt", align_side: true)

    #6)School ==========================================================================================================
    assignment = school.children.create(name: "Assignment (#{school.name.downcase})")
    assignment.children.create(name: "Assignment (#{school.name.downcase})")
    assignment.children.create(name: 'School paper')
    assignment.children.create(name: 'School project')
    school.children.create(name: "Directory (#{school.name.downcase})")
    school.children.create(name: "ID card (#{school.name.downcase})")
    school.children.create(name: "General school info")
    school.children.create(name: "Invoice (#{school.name.downcase})")
    school.children.create(name: "List (#{school.name.downcase})")
    school.children.create(name: 'Report card')
    school.children.create(name: "Teacher's notes")
    school.children.create(name: 'Test scores')
    school.children.create(name: 'Tuition/registration')

    school.children.create(name: "Achievement (#{school.name.downcase})", align_side: true)
    school.children.create(name: "Contact info (#{school.name.downcase})", align_side: true)
    school.children.create(name: "Calendar (#{school.name.downcase})", align_side: true)
    school.children.create(name: 'Diploma', align_side: true)
    school.children.create(name: "Estimate (#{school.name.downcase})", align_side: true)
    school.children.create(name: "Handbook/rules (#{school.name.downcase})", align_side: true)
    school.children.create(name: "Receipt (#{school.name.downcase})", align_side: true)
    school.children.create(name: 'Writing sample', align_side: true)
  end

  desc "adding category_id to production documents"
  task :add_category_id => :environment  do
    Document.update_all(category_id: Category.where(name: Document::PHOTOGRAPH).first.id, tags_array: ["ID & vital records", "Identity Photo" ])
    puts "Successfully Done."
  end


  desc "Creating sample hospital"
  task :create_hospitals => :environment  do
    Hospital.destroy_all
    puts "hospitals creating........."
    Hospital.create!(name:"piedmontmedicalcenter",preferred_name:"piedmontmedicalcenter",address1: "Secundrabad", address2:"Hyderabad", :zipcode=>"01462", :logo_from_url=>"http://www.piedmontmedicalcenter.com/sitecollectionimages/logo.gif")
    Hospital.create!(name:"Yashoda care",preferred_name:"Yashoda",address1: "Suryapet", address2:"Nalgonda", :zipcode=>"01453",:logo_from_url=>"http://www.mykidslink.com/app/app/v2/images/tempsponsorlogo_drgreene.png")

    puts "Successfully Done."
  end

  desc "Add default hospital_id to organization"
  task add_hospital_id_to_org: :environment  do
    organization = Organization.first
    hospital = Hospital.onboarding.first
    if organization and hospital
      # remove attribute hospital_id if already exists
      organization.unset(:hospital_id) if organization.respond_to?(:hospital_id)
      organization[:hospital_id] = hospital.id
      organization.save
    else
      puts "*** ERROR:  either hospital or organization are not found.Please check and run task again"
    end
    puts "--- Successfully added default hospital_id to Organization."
  end

  desc "Parse bithdate from string to Date"
  task parse_birthdate_to_date: :environment  do
    kid_profiles =  Profile.where(:kids_type.exists=>true).map(&:kids_type)
    #newly added before_validation callback will take care about parsing the birthdate from string to date so just save record again
    kid_profiles.map(&:save)
  end

  desc "adding Partner branding to profiles"
  task add_partner_branding: :environment  do
    Profile.where(:kids_type.exists=>true).each do |profile|
      HospitalMembership.create(profile_id: profile.id)
    end
    puts "--- Successfully created Hospital Membership"
  end

  desc "Recreating versions to existing  Photographs"
  task recreate_photographs: :environment  do
    Document.all.each_with_index do |doc, index|
      #doc.source.send(:remove_versions!)
      begin
        doc.process_source_upload = true
        doc.source.recreate_versions!
        doc.save!

      rescue
        next
      end
      puts "***  #{index+1} "
    end
    puts "--- **********Successfully done*************---"
  end

  ### V1 Mobile release items ###
  desc "Update Milestones for capuring timestamp"
  task touch_milestones: :environment do
    Milestone.all.each {|arg0| arg0.touch}
  end


  ### V2.05 tasks
  desc "create attribute snapshot_created for existing milestones to generate snapshot(thumbnail) milestone image through scheduler"
  task add_snapshot_created_to_milestones: :environment do
    Milestone.where(:snapshot_created.exists=> false).update_all(snapshot_created: false)
  end

  ### V2.07  tasks
  desc "Enable document sharing b/w family for already existed profiles"
  task enable_document_sharing: :environment do
    puts "This job will takes some time to finish....."
    parent_profiles = Profile.where(:parent_type.exists=> true)
    parent_profiles.each do |parent_profile|
      unless parent_profile.family_profiles.blank?
        parent_profile.family_profiles.each do |other_parent|
          parent_profile.push(docs_shared_to: other_parent.id)  unless parent_profile.docs_shared_to.include?(other_parent.id)
        end
      end
    end
    puts "---- Successfully enabled document sharing b/w family members :)"
  end

  desc "insert season's created_at with org_mem.meta_data.kid_profile_created_at or parents user created_at if its nil"
  task fix_org_enrolles_application_date: :environment do
    puts "This job will takes some time to finish....."
    org_memberships =  OrganizationMembership.where(:"seasons.created_at".exists=>false)
    newly_added_with_user = 0
    newly_added = 0
    org_memberships.each do |org_mem|
      org_mem.seasons.each do |season|
        if org_mem.meta_data.respond_to?(:kid_profile_created_at)  and org_mem.meta_data.kid_profile_created_at.nil?
          parent = org_mem.profile.parent_profiles.first
          if parent
            user = User.where(email: parent.parent_type.email).first
            if user and !user.created_at.nil?
              season.update_attribute(:created_at,user.created_at) if user
              newly_added_with_user += 1
            end
          end
        else
          season.update_attribute(:created_at,org_mem.meta_data.kid_profile_created_at)
          org_mem.meta_data.unset(:kid_profile_created_at) # remove field
          newly_added += 1
        end
      end
    end
    puts "---- Success: total #{newly_added_with_user} kid_profile_created_at nils are updated with user created_at."
    puts "----          total #{newly_added} season created_at added with kid_profile_created_at"
  end

### V2.08tasks

    desc "To add unsubscribe email feature"
    task add_unsubscribe_emails_field: :environment do
      Profile.where(:parent_type.exists=>true).map(&:save)
    end

### V2.09tasks
  desc "moving photographs from gridfs to Amazon s3."
  # rake db:move_photograph_to_s3 domain="<give domain name>"
  # note: make sure domain is running in other window.
  task move_photograph_to_s3: :environment do
    count = 0
    photographs =Document.where(:source.exists=>true)
    photographs.each do |doc|
      begin
        doc.update_attributes(:remote_source_url=> "#{ENV['domain']}/uploads/document/source/#{doc.id}/#{doc[:source]}")
        count = count+1
          puts "#{count}"
      rescue
        next
      end
    end
    puts "#{count}/#{photographs.count}  successfully moved."
  end

end
