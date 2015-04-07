# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
puts 'EMPTY THE MONGODB DATABASE'
Mongoid::Sessions.default.collections.reject { |c| c.name =~ /^system/}.each(&:drop)

#puts 'SETTING UP DEFAULT USER LOGIN'
user = User.create! :fname => 'Super Admin', :email => 'superadmin@maisasolutions.com', :password => '123456', :password_confirmation => '123456'
user.create_role(:super_admin)

puts "------------------- Creating Organization ....."
organization = Organization.create!(email: 'admin@hpc.com',networkId: 'ms_org_01',name: 'Hyderabad Public School',preffered_name: "HPC",
                                    fax_no: '',address1: "3434 Roswell Road", address2: "Atlanta GA 30305",address3: '',phone_no: '404.842.5809')

puts "----------- Creating admin ...."
admin = User.create! fname: 'Org admin',email: 'maisa.engineers@gmail.com',password: '123456',password_confirmation: '123456'
admin.create_role(:org_admin,[organization.id])

puts "------------------- Creating seasons ....."
organization.seasons.create!({season_year: '2015-2016',is_current: 1,season_fee: 100})
organization.seasons.create!({season_year: '2014-2015',is_current: 0,season_fee: 150})




puts "------------------- Creating sessions ....."
organization.seasons.each do |season|
  [ "Nursery",
    "LKG",
    "UKG",
    "1st Class",
    "2nd Class",
    "3rd Class",
    "4th Class",
    "5th Class",
    "7th Class"
  ].each do |element|
    season.sessions.create!(session_name: element.gsub("2015",season.season_year.split('-')[1]),session_open: '1')
  end
end
puts "------------------- Creating weblinks ....."
organization.weblinks.create({link_name: 'website',link_url: 'http://maisasolutions.com'})
organization.weblinks.create({link_name: 'blog',link_url: 'http://www.maisasolutions.com'})

=begin

puts "------------------- Creating Admin user for the above organization ....."
user = User.create!(email: 'maisa.engineers@gmail.com', fname: "Admin", password: '123456', password_confirmation: '123456')
user.create_role(:org_admin,organization.id)
puts "----------   DONE --------------------------------------------"
=end

organization.seasons.each do |season|
# Create Json Template -- Application Form
  json_template = organization.json_templates.build(category: 'Application Form',form_name: "Application form for #{season.season_year}",form_status: 'active',
                                                    season_id: season.id,workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form])
  json_template.content =  <<EOS
{"form":{"name":"Application form for #{season.season_year}","season":"#{season.season_year}","panel":[{"name":"Child Information","field":[{"id":"fname","name":"First name","unique":"univ","required":"true"},{"id":"lname","name":"Last name","unique":"univ","required":"true"},{"id":"nickname","name":"Preferred name/nickname","unique":"univ","required":"true"},{"id":"gender","name":"Sex","unique":"univ","type":"select","selection_list":["Male","Female"],"lookup":"sex","required":"true"},{"id":"birthdate","name":"Birthdate","unique":"univ","type":"date","required":"true"},{"id":"food_allergies","name":"Food allergies","unique":"univ","type":"textarea","required":"false"},{"id":"medical_issues","name":"Medical issues","unique":"univ","type":"textarea","required":"false"},{"id":"special_needs","name":"Special needs","unique":"univ","type":"textarea","required":"false"},{"id":"other_concerns","name":"Other concerns","unique":"univ","type":"textarea","required":"false"}]},{"name":"Enrollment","field":[{"id":"family_currently_enrolled","name":"Family currently enrolled?","unique":"seas","type":"select","lookup":"yesno","selection_list":["Yes","No"],"required":"true"},{"id":"active_member_of_ppc","name":"Active members of Peachtree Presbyterian Church?","unique":"seas","type":"select","selection_list":["Yes","No"],"lookup":"yesno","required":"true"},{"id":"age_group_and_school_days","name":"Age group and school days","unique":"seas","type":"select","lookup":"sessions","required":"true"},{"id":"secondary_choice_of_class_days","name":"Secondary choice of class days","unique":"seas","required":"false"},{"id":"are_you_enrolling_siblings","name":"Are you enrolling siblings today?","unique":"seas","type":"select","selection_list":["Yes","No"],"lookup":"yesno","required":"true"},{"id":"sibling_name","name":"Sibling's name","unique":"seas","required":"false"},{"id":"sibling_age","name":"Sibling's age group","unique":"seas","required":"false"},{"id":"sibling_days","name":"Sibling's days","unique":"seas","required":"false"}]},{"name":"Address","field":[{"id":"address1","name":"Address (Line 1)","unique":"univ","required":"true"},{"id":"address2","name":"Address (Line 2)","unique":"univ","required":"false"},{"id":"city","name":"City","unique":"univ","required":"true"},{"id":"state","name":"State","unique":"univ","required":"true"},{"id":"zip","name":"Zip","unique":"univ","required":"true"}]},{"name":"Parents","fieldgroup":{"multiply":"true","multiply_default":2,"multiply_link":"Add Additional Parents","field":[{"id":"child_relationship","name":"Parent relationship","unique":"parent","type":"select","selection_list":["Father","Mother","Step-father","Step-mother","Grandmother","Grandfather","Guardian","Other"],"required":"true"},{"id":"fname","name":"First name","unique":"parent","required":"true"},{"id":"lname","name":"Last name","unique":"parent","required":"true"},{"id":"email","name":"E-mail address","unique":"parent","required":"true"},{"id":"phone1","name":"Phone number #1","unique":"parent","type":"phone","selection_list":["Home","Mobile","Work"],"required":"true"},{"id":"phone2","name":"Phone number #2","unique":"parent","type":"phone","selection_list":["Home","Mobile","Work"],"required":"false"},{"id":"phone3","name":"Phone number #3","unique":"parent","type":"phone","selection_list":["Home","Mobile","Work"],"required":"false"}]}},{"name":"Admission Agreement","field":[{"id":"agreement_1","name":"I understand that to complete this application, I will pay a non-refundable $125 registration fee. I hereby agree to pay the tuition in three equal installments due April 16, 2013, November 1, 2013, and February 3, 2014. I understand that tuition is non-refundable except as outlined in the Preschools limited tuition refund policy stated in the Admissions section of the Preschool website.","unique":"seas","type":"check_box","reverse":"true","required":"true"},{"id":"ack_signature","name":"Signature","unique":"seas","type":"ack"},{"id":"ack_date","name":"Date","unique":"seas","type":"ack"}]}]}}
EOS
  json_template.save!
end
=begin

json_template = JsonTemplate.first




# create a user
user = User.create!(:email=>'upender.devulapally@gmail.com', :fname => "Upender",password: 'upender123', password_confirmation: 'upender123')
kid_profile = Profile.create!(:kids_type => ProfileKidsType.new(address1: 'LB Nagar',address2: 'H-NO 555',birthdate: '12/15/2010',fname: 'Madhukar',
                                                                lname: 'Devulapally',nickname: 'buddygaadu',city: 'Hyderabad',state: 'Telangana',
                                                                zip: '123456',gender: 'Male',food_allergies: 'Yes',medical_issues: 'No',other_concerns: 'Be careful',
                                                                special_needs: "Yes"))

parent_profile = Profile.create!(:parent_type => ProfileParentType.new(:fname => user.fname, :lname =>'Devulapally' , :email =>user.email, :parent_id =>'KL123456',
                                                                       :phone_numbers => [PhoneNumber.new(:contact =>'1', :type => 'Home',key: 'phone1'),
                                                                                          PhoneNumber.new(:contact =>'2', :type => 'Mobile',key: 'phone2'),
                                                                                          PhoneNumber.new(:contact =>'3', :type => 'Work',key: 'phone3')],
                                                                       :profiles_manageds => [ProfilesManaged.new(:child_relationship => 'Father', :kids_profile_id => kid_profile.id)]))
org_membership = kid_profile.organization_memberships.build(org_id: organization.id,profile_id: kid_profile.id)
org_membership.save!
season = org_membership.seasons.create!(active_member_of_ppc: 'Yes',age_group_and_school_days: organization.current_season.sessions.map(&:session_name).sample,
                                        are_you_enrolling_siblings: 'Yes',is_current: 0,family_currently_enrolled: 'Yes',season_year: organization.current_season.season_year,
                                        status: 'active')

#create application form with submitted
season.notifications << NormalNotification.new(organization_membership_id: org_membership.id,category: Notification::CATEGORIES[:form],
                                               is_accepted: 'Application submitted', json_template_id: json_template.id,user_id: user.id,acknowledgment_date: Time.now,submitted_count: 1)
#season_document = season.season_documents.build(is_accepted: 'Application submitted',json_template_id: json_template.id,status: 'active')


user.create_role(:parent)


#create  Acknowledgments
#Acknowledgment.create!(user_id: user.id,user_name: user.fname ,season: season.season_year, org_id: organization.id, kids_id: kid_profile.id, form_id: '', acknowledgment_name: 'application', acknowledgment_at: Time.now)
user.acknowledgments.create!(user_name: user.fname,:season => season.season_year, :org_id => organization.id, :kids_id => kid_profile.id, :form_id => '', :acknowledgment_name => 'payment', :acknowledgment_at => Time.now)
#payment_renewed
user.acknowledgments.create!(user_name: user.fname,:season =>season.season_year, :org_id => organization.id, :kids_id => kid_profile.id, :form_id => '', :acknowledgment_name => 'payment_renewed', :acknowledgment_at => Time.now)


puts "---- creating document definitions/normal forms for org-wide/season-wide"
## Create Photograph of child (season-wide)
photo_document_definition = organization.document_definitions.create!(season_id: organization.current_season.id,name: DocumentDefinition::PHOTOGRAPH,workflow: DocumentDefinition::WORKFLOW_TYPES[:auto],is_for_season: true)
#send photograph document definition to kid
season.notifications << NormalNotification.new(organization_membership_id: org_membership.id,category: Notification::CATEGORIES[:document],is_accepted: 'requested',document_definition_id: photo_document_definition.id)

## Create Document Organization-wide
org_document_definition = organization.document_definitions.create!(name: 'Birth certificate',workflow: DocumentDefinition::WORKFLOW_TYPES[:auto])
#send organization-wide document definition to kid
org_membership.notifications << NormalNotification.create!(category: Notification::CATEGORIES[:document],is_accepted: 'requested',document_definition_id: org_document_definition.id)

## Create Document Season-wide
seas_document_definition = organization.document_definitions.create!(season_id: organization.current_season.id,name: "Proof of church membership",is_for_season: true)
#send season-wide document definition to kid
season.notifications << NormalNotification.create(organization_membership_id: org_membership.id,category: Notification::CATEGORIES[:document],is_accepted: 'requested',document_definition_id: seas_document_definition.id)

#create field-trip normal form
field_trip_json_template = organization.json_templates.build(category: 'Field trip',form_name: 'Zoo Atlanta Field Trip 3/30/2013',form_status: 'active',
                                                             season_id: organization.current_season.id,workflow: JsonTemplate::WORKFLOW_TYPES[:normal])
field_trip_json_template.content =  <<EOS
{"form":{"id":123456789,"name":"Zoo Atlanta Field Trip 3/30/2013","season":"2013-2014","panel":[{"name":"Child Information","field":[{"id":"fname","name":"First name","unique":"univ","required":"true"},{"id":"lname","name":"Last name","unique":"univ","required":"true"},{"id":"nickname","name":"Preferred name/nickname","unique":"univ","required":"true"},{"id":"gender","name":"Sex","unique":"univ","type":"select","selection_list":["Male","Female"],"lookup":"sex","required":"true"}]},{"name":"Field Trip Authorization","field":[{"id":"field_trip_2013_03_30","name":"Field Trip Authorization 3/30/2013","name":"I want my child to attend this field trip and I accept all the liability for it.","unique":"seas","type":"check_box","required":"true"}]}]}}
EOS
field_trip_json_template.save!
#send season-wide fieldtrip form
season.notifications << NormalNotification.new(organization_membership_id: org_membership.id,category: Notification::CATEGORIES[:form],
                                               is_accepted: 'requested',json_template_id: field_trip_json_template.id)
=end


