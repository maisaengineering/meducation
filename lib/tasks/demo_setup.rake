namespace :db do

  desc "Setup form demo"

  task demo_setup: :environment do
    raise "INFO: this task should not be run in production" if Rails.env.production?
    puts 'EMPTY THE MONGODB DATABASE...'
    Mongoid::Sessions.default.collections.reject { |c| c.name =~ /^system/}.each(&:drop)
    puts 'Creating Super Admin..'
    user = User.create! fname: 'Super Admin', email: 'superadmin@maisasolutions.com', password: '123456', password_confirmation: '123456'
    user.create_role(:super_admin)

    Rake::Task["db:setup_organizations"].invoke
    Rake::Task["db:setup_application_forms"].invoke
    Rake::Task["db:setup_enrollments"].invoke
    Rake::Task["db:create_hospital_and_events"].invoke
    Rake::Task["db:create_categories"].invoke
    Rake::Task["db:create_ms_templates"].invoke
    # Rake::Task["db:create_childrens"].invoke
    # Rake::Task["db:create_hospital_and_events"].invoke
  end

  desc "Create Organizations"
  task setup_organizations: :environment do
    (1..3).each do |number|
      org_name = Faker::Company.name
      organization = Organization.create!(email: "maisa.engineers#{number}@gmail.com",networkId: "kl_org_#{number}",name: "Org#{number} #{org_name}", description: '-----',
                                          preffered_name: org_name,fax_no: Faker::PhoneNumber.phone_number,
                                          address1:  Faker::Address.building_number, address2: Faker::Address.street_address,address3: "#{Faker::Address.city} , #{Faker::Address.country}",phone_no: Faker::PhoneNumber.phone_number)

      puts "------------------- Creating 3 seasons for each org....."
      organization.seasons.create!({season_year: "org#{number}/2012-2013",is_current: 1,season_fee: [100,150,200,250].sample})
      organization.seasons.create!({season_year: "org#{number}/2013-2014",is_current: 0,season_fee: [100,150,200,250].sample})
      #organization.seasons.create!({season_year: "org#{number}/2014-2015",is_current: 0})

      puts "------------------- Creating 5 sessions for each org....."
      organization.seasons.each do |season|
        (1..5).each do |element|
          season.sessions.create!(session_name: "#{season.season_year}/session#{element}",session_open: ['1','0'].sample)
        end
      end
      puts "------------------- Creating weblinks for each org ....."
      organization.weblinks.create({link_name: "#{organization.preffered_name}-website",link_url: 'http://mykidslink.com'})
      organization.weblinks.create({link_name: "#{organization.preffered_name}-blog",link_url: 'http://www.maisasolutions.com'})
      puts "------------------- Create Default 3 Admin users for organization ....."
      (1..3).each do |element|
        user = User.create!(email: "admin#{element}@org#{number}.com", fname: "Admin#{element}", password: '123456', password_confirmation: '123456')
        user.create_role(:org_admin,[organization.id])
      end
    end
  end

  desc "Create Application Form for each Organization"
  task setup_application_forms: :environment do
    puts "#----------Creating Application forms"
    Organization.all.each do |organization|
      organization.seasons.each do |season|
        # Create Json Template -- Application Form
        json_template = organization.json_templates.build(category: 'Application Form',form_name: "Application #{season.season_year}",form_status: 'active',
                                                          season_id: season.id,workflow: JsonTemplate::WORKFLOW_TYPES[:appl_form])
        json_template.content =
            <<EOS
            {"form":{"name":"Application #{season.season_year}","season":"#{season.season_year}","panel":[{"name":"Child Information","field":[{"id":"fname","name":"First name","unique":"univ","required":"true"},{"id":"lname","name":"Last name","unique":"univ","required":"true"},{"id":"nickname","name":"Preferred name/nickname","unique":"univ","required":"true"},{"id":"gender","name":"Sex","unique":"univ","type":"select","selection_list":["Male","Female"],"lookup":"sex","required":"true"},{"id":"birthdate","name":"Birthdate","unique":"univ","type":"date","required":"true"},{"id":"food_allergies","name":"Food allergies","unique":"univ","type":"textarea","required":"false"},{"id":"medical_issues","name":"Medical issues","unique":"univ","type":"textarea","required":"false"},{"id":"special_needs","name":"Special needs","unique":"univ","type":"textarea","required":"false"},{"id":"other_concerns","name":"Other concerns","unique":"univ","type":"textarea","required":"false"}]},{"name":"Enrollment","field":[{"id":"family_currently_enrolled","name":"Family currently enrolled?","unique":"seas","type":"select","lookup":"yesno","selection_list":["Yes","No"],"required":"true"},{"id":"active_member_of_ppc","name":"Active members of Peachtree Presbyterian Church?","unique":"seas","type":"select","selection_list":["Yes","No"],"lookup":"yesno","required":"true"},{"id":"age_group_and_school_days","name":"Age group and school days","unique":"seas","type":"select","lookup":"sessions","required":"true"},{"id":"secondary_choice_of_class_days","name":"Secondary choice of class days","unique":"seas","required":"false"},{"id":"are_you_enrolling_siblings","name":"Are you enrolling siblings today?","unique":"seas","type":"select","selection_list":["Yes","No"],"lookup":"yesno","required":"true"},{"id":"sibling_name","name":"Sibling's name","unique":"seas","required":"false"},{"id":"sibling_age","name":"Sibling's age group","unique":"seas","required":"false"},{"id":"sibling_days","name":"Sibling's days","unique":"seas","required":"false"}]},{"name":"Address","field":[{"id":"address1","name":"Address (Line 1)","unique":"univ","required":"true"},{"id":"address2","name":"Address (Line 2)","unique":"univ","required":"false"},{"id":"city","name":"City","unique":"univ","required":"true"},{"id":"state","name":"State","unique":"univ","required":"true"},{"id":"zip","name":"Zip","unique":"univ","required":"true"}]},{"name":"Parents","fieldgroup":{"multiply":"true","multiply_default":2,"multiply_link":"Add Additional Parents","field":[{"id":"child_relationship","name":"Parent relationship","unique":"parent","type":"select","selection_list":["Father","Mother","Step-father","Step-mother","Grandmother","Grandfather","Guardian","Other"],"required":"true"},{"id":"fname","name":"First name","unique":"parent","required":"true"},{"id":"lname","name":"Last name","unique":"parent","required":"true"},{"id":"email","name":"E-mail address","unique":"parent","required":"true"},{"id":"phone1","name":"Phone number #1","unique":"parent","type":"phone","selection_list":["Home","Mobile","Work"],"required":"true"},{"id":"phone2","name":"Phone number #2","unique":"parent","type":"phone","selection_list":["Home","Mobile","Work"],"required":"false"},{"id":"phone3","name":"Phone number #3","unique":"parent","type":"phone","selection_list":["Home","Mobile","Work"],"required":"false"}]}},{"name":"Admission Agreement","field":[{"id":"agreement_1","name":"I understand that to complete this application, I will pay a non-refundable $125 registration fee. I hereby agree to pay the tuition in three equal installments due April 16, 2013, November 1, 2013, and February 3, 2014. I understand that tuition is non-refundable except as outlined in the Preschools limited tuition refund policy stated in the Admissions section of the Preschool website.","unique":"seas","type":"check_box","reverse":"true","required":"true"},{"id":"ack_signature","name":"Signature","unique":"seas","type":"ack"},{"id":"ack_date","name":"Date","unique":"seas","type":"ack"}]}]}}
EOS
        json_template.save!
      end
    end
  end

  desc "Create Parent register two childs for multi organizations and multi seasons"
  task setup_enrollments: :environment do
    puts "#########  Creating 1 demo user(parent) and registering 3 kids"
    # create a user
    birth_dates = [4.days.ago.to_date,4.days.ago.to_date]  #['06/01/2013','05/20/2013','06/01/2013']
    yes_no = ['Yes','No'].sample
    user = User.create!(email: "demouser1@maisasolutions.com", fname: "Demo User",password: '123456', password_confirmation: '123456')
    #Create Membership
    user.create_role(:parent)


    parent_profile = Profile.create!(:parent_type => ProfileParentType.new(fname: user.fname, :lname =>"#{1}" , email: user.email,
                                                                           :phone_numbers => [PhoneNumber.new(:contact =>Faker::PhoneNumber.phone_number, :type => 'Home',key: 'phone1'),
                                                                                              PhoneNumber.new(:contact =>Faker::PhoneNumber.phone_number, :type => 'Mobile',key: 'phone2'),
                                                                                              PhoneNumber.new(:contact =>Faker::PhoneNumber.phone_number, :type => 'Work',key: 'phone3')]))
    #create 3 kids
    (1..2).each do |element|
      kid_profile = Profile.create!(:kids_type => ProfileKidsType.new(address1: Faker::Address.street_address,address2: "H-NO #{Faker::Address.building_number} ",
                                                                      birthdate: birth_dates.sample,fname: "Kid#{element}",
                                                                      lname: Faker::Name.last_name,nickname: "Kid#{element}" ,city: Faker::Address.city,state: Faker::Address.state,
                                                                      zip: ['500218'].sample,gender: ['Male','Female'].sample,food_allergies: yes_no,
                                                                      medical_issues: Faker::Lorem.paragraph,other_concerns: Faker::Lorem.paragraph,special_needs: Faker::Lorem.paragraph))

      #create Mangeads
      parent_profile.parent_type.profiles_manageds.create(child_relationship:'Mother',kids_profile_id: kid_profile.id,manageable:true)
    end



    kid_ids =  parent_profile.parent_type.profiles_manageds.map(&:kids_profile_id)

    #first kid applying first organization and only one season season
    kid1 = Profile.find(kid_ids.first)
    organization = Organization.first
    org_membership = kid1.organization_memberships.build(org_id: organization.id,profile_id: kid1.id)
    org_membership.save!
    season = organization.seasons.first

    mem_season = org_membership.seasons.create!(active_member_of_ppc: yes_no,age_group_and_school_days: season.sessions.where(session_open: '1').map(&:session_name).sample,
                                                are_you_enrolling_siblings: yes_no,is_current: 0,family_currently_enrolled: yes_no,org_season_id: season.id,
                                                status: 'active')
    #create  Acknowledgments
    #Acknowledgment.create!(user_id: user.id,user_name: user.fname ,season: season.season_year, org_id: organization.id, kids_id: kid_profile.id, form_id: '', acknowledgment_name: 'application', acknowledgment_at: Time.now)
    user.acknowledgments.create!(user_name: user.fname,season: season.id, org_id: organization.id, kids_id: kid1.id, :form_id => '', acknowledgment_name: 'payment', acknowledgment_at: Time.now)
    user.acknowledgments.create!(user_name: user.fname,season: season.id, org_id: organization.id, kids_id: kid1.id, :form_id => '', acknowledgment_name: 'payment_renewed', acknowledgment_at: Time.now)
    #create application form with submitted
    json_template = organization.json_templates.find_by(season_id: season.id)
    mem_season.notifications << NormalNotification.new(organization_membership_id: org_membership.id,category: Notification::CATEGORIES[:form],
                                                       is_accepted: 'Application submitted', json_template_id: json_template.id,user_id: user.id,acknowledgment_date: Time.now,submitted_count: 1)


    #second kid applying two organizations and all season
    kid2 = Profile.find(kid_ids.last)
    Organization.limit(2).each do |organization|
      org_membership = kid2.organization_memberships.build(org_id: organization.id,profile_id: kid2.id)
      org_membership.save!
      organization.seasons.each do |season|
        mem_season = org_membership.seasons.create!(active_member_of_ppc: yes_no,age_group_and_school_days: season.sessions.where(session_open: '1').map(&:session_name).sample,
                                                    are_you_enrolling_siblings: yes_no,is_current: 0,family_currently_enrolled: yes_no,org_season_id: season.id,
                                                    status: 'active')
        #create  Acknowledgments
        #Acknowledgment.create!(user_id: user.id,user_name: user.fname ,season: season.season_year, org_id: organization.id, kids_id: kid_profile.id, form_id: '', acknowledgment_name: 'application', acknowledgment_at: Time.now)
        user.acknowledgments.create!(user_name: user.fname,season: season.id, org_id: organization.id, kids_id: kid2.id, :form_id => '', acknowledgment_name: 'payment', acknowledgment_at: Time.now)
        user.acknowledgments.create!(user_name: user.fname,season: season.id, org_id: organization.id, kids_id: kid2.id, :form_id => '', acknowledgment_name: 'payment_renewed', acknowledgment_at: Time.now)
        #create application form with submitted
        json_template = organization.json_templates.find_by(season_id: season.id)
        mem_season.notifications << NormalNotification.new(organization_membership_id: org_membership.id,category: Notification::CATEGORIES[:form],
                                                           is_accepted: 'Application submitted', json_template_id: json_template.id,user_id: user.id,acknowledgment_date: Time.now,submitted_count: 1)


      end
    end


  end



  desc "Create Hospitals"

  task create_hospital_and_events: :environment do
    Hospital.delete_all
    org_name = Faker::Company.name
    #hospital = Hospital.create!(email: "maisa.engineers@gmail.com",name: "Hospital-#{1} #{org_name}",zipcode: '500218',
    #                            preffered_name: org_name,fax_no: Faker::PhoneNumber.phone_number,
    #                            address1:  Faker::Address.building_number, address2: Faker::Address.street_address,
    #                            phone_no: Faker::PhoneNumber.phone_number,description: Faker::Lorem.paragraph)
    user = User.where(email: 'demouser1@maisasolutions.com').first
    kid1 = user.managed_kids[0]
    kid2 = user.managed_kids[1]
    Hospital.destroy_all
    puts "hospitals creating........."
    hospital = Hospital.new(is_default: true,name: "Apollo care",preferred_name: "Apollo",address1: "Secundrabad", address2: "Hyderabad", zipcode: "01462",zipcodes: ['95191', '95002', '95035'])
    hospital.section1 = <<EOD
               <div class="dashCentralButton" id="dashCentralButtonFind" onClick=''>find a doctor</div>
               <div class="dashCentralButton" id="dashCentralButtonNurseChat" onClick=''>nurse chat</div>
EOD
    hospital.section2 = <<EOD
              &nbsp;<br />&nbsp;<br />&nbsp;<br />&nbsp;<br />(marketing section)
EOD
    hospital.section3= <<EOD
          <dl>
             <dt><a href="#">St. Med MyChart</a></dt>
             <dd>Electronic records and hospital billing / patient portal</dd>
             <dt><a href="#">La Leche League</a></dt>
             <dd>Lactation support</dd>
             <dt><a href="#">Breastfeeding Services</a></dt>
             <dd>St. Med @ Nursing Mother's Place</dd>
             <dt><a href="#">Postpartum depression information</a></dt>
             <dd>Video interviews and community support</dd>
           </dl>
           <div style='color: #999; padding-top: 10px; font-size: 12px;'><a href="#">more st. med links</a></div>
EOD
    hospital.section4= <<EOD
             <dl>
               <dt><a href="#">Amazon: Huggies Wipes Deal</a></dt>
                 <dd class="panelRSSBlogName">Mommy Octopus (Athens)</dd>
                 <dd class="panelRSSSummary">More Amazon deals! This time, for Huggies wipes!  Here's how to get a good deal on Huggies Wipes. You MUST be an Amazon mom member to get this price.</dd>
               <dt><a href="#">Running on Empty. Chick-Fil-A Madison 5K</a></dt>
                 <dd class="panelRSSBlogName">South Main Muse (Madison)</dd>
                 <dd class="panelRSSSummary">Early this spring my youngest told me he wanted to run three 5Ks. Three races of 3.1 miles. I wasn't sure. But we signed up for the Chick-Fil-A race that was today in Madison.</dd>
               <dt><a href="#">How to Introduce your Child to Gardening</a></dt>
                 <dd class="panelRSSBlogName">Southern Girl Ramblings (Chatsworth)</dd>
                 <dd class="panelRSSSummary">It's safe to say that most parents want their children to have lots of outdoor play. It's good to get them away from the TV and game consoles so that they get the Vitamin D needed and to burn off the bundles of energy that little ones possess.</dd>
             </dl>

             <div class="panelActionContainer">
               <ul>
                 <li><a href="#">view all recent community posts</a></li>
               </ul>
             </div>
EOD
    hospital.save!
    Organization.update_all(hospital_id: hospital.id)
    # hospital2=  Hospital.create!(name:"Yashoda care",preffered_name:"Yashoda",address1: "Suryapet", address2:"Nalgonda", :zipcode=>"01453", :find_a_doctor=> "http://www.yashodahospitals.com/onlineappointment.aspx", :nurse_chat =>"http://www.yashodahospitals.com/onlineappointment.aspx",:logo_from_url=>"http://www.yashodahospitals.com/images/logo.jpg",  weblinks:[{link_name: "Yashoda link1", link_url:"http://www.maisasolutions.com"},{link_name: "Yashoda link2", link_url:"http://www.kidslink.com"}])
    # hospital3 = Hospital.create!(name:"Medi city",preffered_name:"Medi",address1: "Kukatpally", address2:"Hyderabad", :zipcode=>"01473", :find_a_doctor=> "http://hie.medicity.com/Contact_Us_form_1.html", :nurse_chat=>"http://hie.medicity.com/Contact_Us_form_1.html",:logo_from_url=>"http://hie.medicity.com/rs/aetnainc/images/MDC_Logo_MU.png", weblinks:[{link_name: "Medicity link1", link_url:"http://www.maisasolutions.com"},{link_name: "Medicity link2", link_url:"http://www.kidslink.com"}])
    #create two adhoc events  and assign to kids
    AeDefinition.destroy_all
    #Event

    #create ScheduledAlertDefintion and assign to kids
    ScheduledAeDefinition.create!(to_whom: 'kid',hospital_id: hospital.id,definition_type: AeDefinition::DEFINITION_TYPES[:alert],title: 'Schedule 1st well-baby check',
                                  sub_line: Faker::Lorem.sentence,content: Faker::Lorem.paragraph,occurring_days: 4,due_by_days: 10,request_buttons: [AeDefinition::REQUEST_BUTTONS[:ive_done_it],AeDefinition::REQUEST_BUTTONS[:ignore]])

    ScheduledAeDefinition.create!(to_whom: 'kid',hospital_id: hospital.id,definition_type: AeDefinition::DEFINITION_TYPES[:alert],title: 'Schedule 2nd well-baby check',
                                  sub_line: Faker::Lorem.sentence,content: Faker::Lorem.paragraph,occurring_days: 4,due_by_days: 15,request_buttons: [AeDefinition::REQUEST_BUTTONS[:ive_done_it],AeDefinition::REQUEST_BUTTONS[:ignore],AeDefinition::REQUEST_BUTTONS[:thanks]])

    HospitalMembership.create(profile_id: kid1.id,hospital_id: hospital.id)
    HospitalMembership.create(profile_id: kid2.id,hospital_id: hospital.id)

    ad_hoc_ae_definition1= AdHocAeDefinition.create!(to_whom: 'parent',hospital_id: hospital.id,definition_type: AeDefinition::DEFINITION_TYPES[:event],title: 'Parent-Flu shot event-1',
                                                     sub_line: Faker::Lorem.sentence,content: Faker::Lorem.paragraph,request_buttons: [AeDefinition::REQUEST_BUTTONS[:ive_done_it],AeDefinition::REQUEST_BUTTONS[:thanks]])
    #Alert
    ad_hoc_ae_definition2 = AdHocAeDefinition.create!(to_whom: 'kid',hospital_id: hospital.id,definition_type: AeDefinition::DEFINITION_TYPES[:event],title: 'Kid-Medical camp-1',
                                                      sub_line: Faker::Lorem.sentence,content: Faker::Lorem.paragraph,request_buttons: [AeDefinition::REQUEST_BUTTONS[:ive_done_it],AeDefinition::REQUEST_BUTTONS[:ignore],AeDefinition::REQUEST_BUTTONS[:thanks]])


    ad_hoc_ae_definition3 = AdHocAeDefinition.create!(to_whom: 'parent',hospital_id: hospital.id,definition_type: AeDefinition::DEFINITION_TYPES[:event],title: 'Parent-Flu shot event-2',
                                                      sub_line: Faker::Lorem.sentence,content: Faker::Lorem.paragraph,request_buttons: [AeDefinition::REQUEST_BUTTONS[:ive_done_it],AeDefinition::REQUEST_BUTTONS[:ignore],AeDefinition::REQUEST_BUTTONS[:thanks]])

    ad_hoc_ae_definition4 = AdHocAeDefinition.create!(to_whom: 'kid',hospital_id: hospital.id,definition_type: AeDefinition::DEFINITION_TYPES[:event],title: 'Kid-Medical camp-2',
                                                      sub_line: Faker::Lorem.sentence,content: Faker::Lorem.paragraph,request_buttons: [AeDefinition::REQUEST_BUTTONS[:ive_done_it],AeDefinition::REQUEST_BUTTONS[:ignore],AeDefinition::REQUEST_BUTTONS[:thanks]])

    ad_hoc_ae_definition5 = AdHocAeDefinition.create!(to_whom: 'kid',hospital_id: hospital.id,definition_type: AeDefinition::DEFINITION_TYPES[:event],title: 'Kid-Medical camp-3',
                                                      sub_line: Faker::Lorem.sentence,content: Faker::Lorem.paragraph,request_buttons: [AeDefinition::REQUEST_BUTTONS[:ive_done_it],AeDefinition::REQUEST_BUTTONS[:ignore],AeDefinition::REQUEST_BUTTONS[:thanks]])

    ad_hoc_ae_definition6 = AdHocAeDefinition.create!(to_whom: 'kid',hospital_id: hospital.id,definition_type: AeDefinition::DEFINITION_TYPES[:event],title: 'Kid-Medical camp-4',
                                                      sub_line: Faker::Lorem.sentence,content: Faker::Lorem.paragraph,request_buttons: [AeDefinition::REQUEST_BUTTONS[:ive_done_it],AeDefinition::REQUEST_BUTTONS[:ignore],AeDefinition::REQUEST_BUTTONS[:thanks]])

    ad_hoc_ae_definition6 = AdHocAeDefinition.create!(to_whom: 'parent',hospital_id: hospital.id,definition_type: AeDefinition::DEFINITION_TYPES[:event],title: 'Parent-Flu shot event-3',
                                                      sub_line: Faker::Lorem.sentence,content: Faker::Lorem.paragraph,request_buttons: [AeDefinition::REQUEST_BUTTONS[:ive_done_it],AeDefinition::REQUEST_BUTTONS[:ignore],AeDefinition::REQUEST_BUTTONS[:thanks]])





    puts "Successfully Done."





  end


  task create_ms_templates: :environment do
    MilestoneTemplate.destroy_all
    content = <<EOD
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<style type="text/css">

body {
padding: 0px;
margin: 0px;
}

.mstWrapper_1stpet_1 {
padding: 0px;
margin-left: auto;
margin-right: auto;
margin-top: 0px;
margin-bottom: 0px;
position: relative;
-webkit-transform: scale(.5);
-webkit-transform-origin: left top;
-ms-transform: scale(.5);
-ms-transform-origin: left top;
-transform: scale(.5);
-transform-origin: left top;
}

.mstWrapper_1stpet_1 .mstContainer {
background-image: url(https://test-ms-templates.s3.amazonaws.com/assets/template_image/source/523b2a55e0db560907000019/mst_bg.jpg);
background-position: center center;
background-repeat: no-repeat;
font-family: "ProximaNova-Regular", Arial, Helvetica, sans-serif;
font-size: 25px;
font-weight: normal;
width: 900px;
height: 643px;
position: relative;
}

.mstWrapper_1stpet_1 .mstBody {
height: 578px;
width: 412px;
position: relative;
left: 448px;
margin-left: 20px;
margin-right: 20px;
text-align: center;
}

.mstWrapper_1stpet_1 .mstChildPrefNamePoss {
font-size: 55px;
color: #777;
padding-top: 58px;
line-height: 58px;
/*text-transform: upperlowercase;*/
font-family: "ConeriaScriptMedium", "Palatino Linotype", "Book Antiqua", Palatino, serif;
}

.mstWrapper_1stpet_1 .mstMilestoneName {
font-size: 64px;
line-height: 58px;
color: #0aaae8;
text-transform: uppercase;
/*font-family: "ConeriaScriptMedium", "Palatino Linotype", "Book Antiqua", Palatino, serif;*/
}

.mstWrapper_1stpet_1 .mstMilestoneDate {
font-size: 25px;
line-height: 25px;
color: #fff;
background-color: #bfbfbf;
height: 28px;
padding-top: 4px;
width: 340px;
margin-left: auto;
margin-right: auto;
margin-top: 5px;
}

.mstWrapper_1stpet_1 .mstMilestoneText {
font-size: 35px;
color: #777;
line-height: 1.2em;
}

.mstWrapper_1stpet_1 .mstMilestoneText table {
width: 100%;
height: 145px;
}

.mstWrapper_1stpet_1 .mstMilestoneText td {
vertical-align: middle;
text-align: center;
}

.mstWrapper_1stpet_1 .mstPhoto {
position: absolute;
left: 89px;
top: 120px;
width: 272px;
height: 355px;
background-position: center center;
background-repeat: no-repeat;
background-size: auto 355px;
text-align: center;
}

.mstWrapper_1stpet_1 .mstPhotoTemp {
opacity: .3;
filter: alpha(opacity=30);
}

.mstWrapper_1stpet_1 .mstPhotoTemp:before {
content: "\A \A \A add your own photo";
white-space: pre-wrap;
width: 100%;
text-align: center;
color: #000;
font-size: 30px;
}

.mstWrapper_1stpet_1 .mstFooter {
height: 65px;
background-color: #0aaae8;
background-image: url(http://s3.amazonaws.com/kidslink-test/assets/milestones/521d7fc6af0665db87000005/msg_kllogo.png?1377664966);
background-position: 505px center;
background-repeat: no-repeat;
padding-left: 40px;
padding-right: 495px;
text-align: center;
}

.mstWrapper_1stpet_1 .mstSponsor {
display: inline-block;
margin-left: auto;
margin-right: auto;
margin-top: -25px;
text-align: center;
height: 90px;
background-color: #bfbfbf;
padding-left: 15px;
padding-right: 15px;
border-left: solid 4px #fff;
border-right: solid 4px #fff;
position: relative;
z-index: 1;
}

.mstWrapper_1stpet_1 .mstSponsor table {
width: 100%;
height: 100%;
margin: 0px;
padding: 0px;
}

.mstWrapper_1stpet_1 .mstSponsor td {
width: 100%;
height: 100%;
vertical-align: middle;
}

</style>
</head>
<body>

<div class="mstWrapper_1stpet_1">
<div class="mstContainer">

<div class="mstBody">
<div class="mstChildPrefNamePoss">{{ KIDSLINK.nickName }}'s</div>
<div class="mstMilestoneName">First Pet</div>
<div class="mstMilestoneDate">{{ KIDSLINK.date }}</div>
<div class="mstMilestoneText"><table><tr><td>New best friends!</td></tr></table></div>
</div>

{{#if KIDSLINK.photo}}
<div class="mstPhoto" style="background-image: url({{ KIDSLINK.photo }});"></div>
{{else}}
<div class="mstPhoto
{{#if KIDSLINK.photo}}
{{ else }}
{{#if KIDSLINK.mPersisted }}
{{ else }}
mstPhotoTemp
{{/if }}
{{/if}}
" style="background-image: url(https://test-ms-templates.s3.amazonaws.com/assets/template_image/source/523b2a55e0db56090700001a/mst_temp_photo.jpg);">
</div>
{{/if}}

<div class="mstFooter">
{{#if KIDSLINK.hospitalLogo}}
{{#ifEqual KIDSLINK.hospitalOptedOut false}}
<div class="mstSponsor"><table><tr><td><img src="{{KIDSLINK.hospitalLogo}}"/>
</td></tr></table>
</div>
{{/ifEqual}}
{{/if}}
</div>
</div>
</div>
</body>
</html>

EOD
    a_start = (0..5).to_a
    a_end = (1..10).to_a
    gender = ['Female','Male',nil]
    (0..25).to_a.each do |v|
      start = a_start.sample
      aend = a_end.sample
      if aend > start
        ms_template = MilestoneTemplate.new(name: "MST Age-#{v}",gender: gender.sample)
        ms_template.build_age_validity(start: start,end: aend)
        ms_template.designs.build(content: content)
        # ms_template.build_holiday_validity(start: a_start.sample.days.ago,end: a_end.sample.days.ago)
        ms_template.save!
      end
    end


    mst =  MilestoneTemplate.new(name: "MST Holiday 1",gender: 'Female',holiday_validity: {start: 5.days.ago.to_date,end: 4.days.ago.to_date}) #expired
    mst.designs.build(content: content)
    mst.save!
    mst =  MilestoneTemplate.new(name: "MST Holiday 2",holiday_validity: {start: 3.days.ago.to_date,end: 3.days.ago.to_date}) #expired
    mst.designs.build(content: content)
    mst.save!


    mst =  MilestoneTemplate.new(name: "MST Holiday 3",holiday_validity: {start: 20.days.ago.to_date,end: Date.today}) #not-expired
    mst.designs.build(content: content)
    mst.save!
    mst =  MilestoneTemplate.new(name: "MST Holiday 4",holiday_validity: {start: 10.days.ago.to_date,end: 2.days.from_now.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Holiday 5",holiday_validity: {start: 5.days.ago.to_date,end: 8.days.from_now.to_date}) #expired
    mst.designs.build(content: content)
    mst.save!


    mst = MilestoneTemplate.new(name: "MST Holiday 6",gender: 'Female',holiday_validity: {start: 6.days.ago.to_date,end: 3.days.ago.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!
    mst =  MilestoneTemplate.new(name: "MST Holiday 7",gender: 'Male',holiday_validity: {start: 5.days.ago.to_date,end: 4.days.from_now.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!
    mst =  MilestoneTemplate.new(name: "MST Holiday 8",gender: 'Female',holiday_validity: {start: 4.days.ago.to_date,end: 5.days.from_now.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!
    mst = MilestoneTemplate.new(name: "MST Holiday 9",holiday_validity: {start: 3.days.ago.to_date,end: 1.days.ago.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!
    mst =  MilestoneTemplate.new(name: "MST Holiday 10",gender: 'Male',holiday_validity: {start: 3.days.ago.to_date,end: 7.days.from_now.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Holiday 11",gender: 'Female',holiday_validity: {start: 6.days.ago.to_date,end: 20.days.from_now.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Holiday 12",holiday_validity: {start: 8.days.ago.to_date,end: 25.days.from_now.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Holiday 13",holiday_validity: {start: 10.days.ago.to_date,end: 3.days.ago.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Holiday 14",holiday_validity: {start: 20.days.ago.to_date,end: 15.days.from_now.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Holiday 15",gender: 'Female',holiday_validity: {start: 10.days.ago.to_date,end: 20.days.from_now.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Holiday 16",holiday_validity: {start: 10.days.ago.to_date,end: 3.days.ago.to_date}) #not-expired
    mst.designs.build(content: content)
    mst.save!

    #-------------------  Age + Holiday Validity

    mst =  MilestoneTemplate.new(name: "MST Age Holiday 1",holiday_validity: {start: 3.days.ago.to_date,end: 7.days.from_now.to_date}, age_validity: {start: 3 ,end: 5})
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Age Holiday 2",holiday_validity: {start: 3.days.ago.to_date,end: 1.days.from_now.to_date}, age_validity: {start: 5 ,end: 10})
    mst.designs.build(content: content)
    mst.save!


    mst =  MilestoneTemplate.new(name: "MST Age Holiday 3",holiday_validity: {start: 3.days.ago.to_date,end: 5.days.from_now.to_date},age_validity: {start: 4 ,end: 6})
    mst.designs.build(content: content)
    mst.save!



    mst =  MilestoneTemplate.new(name: "MST Age Holiday 4",holiday_validity: {start: 3.days.ago.to_date,end: 4.days.from_now.to_date},age_validity: {start: 7 ,end: 10})
    mst.designs.build(content: content)
    mst.save!


    mst =  MilestoneTemplate.new(name: "MST Age Holiday 5",holiday_validity: {start: 10.days.ago.to_date,end: 7.days.ago.to_date},age_validity: {start: 4 ,end: 8})
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Age Holiday 6",holiday_validity: {start: 12.days.ago.to_date,end: 7.days.from_now.to_date},age_validity: {start: 4 ,end: 8})
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Age Holiday 7",gender: 'Male',holiday_validity: {start: 5.days.ago.to_date,end: 2.days.from_now.to_date},age_validity: {start: 4 ,end: 8})
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Age Holiday 8",gender: 'Female',holiday_validity: {start: 20.days.ago.to_date,end: 15.days.from_now.to_date},age_validity: {start: 4 ,end: 8})
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Age Holiday 9",holiday_validity: {start: 11.days.ago.to_date,end: 12.days.from_now.to_date},age_validity: {start: 4 ,end: 8})
    mst.designs.build(content: content)
    mst.save!

    mst =  MilestoneTemplate.new(name: "MST Age Holiday 10",gender: 'Female',holiday_validity: {start: 13.days.ago.to_date,end: 7.days.from_now.to_date},age_validity: {start: 4 ,end: 8})
    mst.designs.build(content: content)
    mst.save!


    #(25..50).to_a.each do |v|
    #  start = a_start.sample
    #  aend = a_end.sample
    #  if aend > start
    #    ms_template = MilestoneTemplate.new(name: "MST Age-#{v}",gender: gender.sample)
    #    ms_template.build_age_validity(start: start,end: aend)
    #    ms_template.designs.build(content: content)
    #    # ms_template.build_holiday_validity(start: a_start.sample.days.ago,end: a_end.sample.days.ago)
    #    ms_template.save!
    #  end
    #end

  end



end

