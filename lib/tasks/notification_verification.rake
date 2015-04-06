namespace :db do

  desc "verification of Forms requested from organization"
  task check_forms_kids: :environment do
    json_template_ids = ENV['TemplateIds'].split()
    none_form = all_form = 0
    org_members =  Organization.first.organization_memberships.where("seasons.season_year"=>"2013-2014")
    org_members.each do |org_member|
      diff = json_template_ids - org_member.notifications.map(&:json_template_id).uniq.map(&:to_s)
      if !diff.empty? and diff.count != json_template_ids.count
        puts "#{org_member.profile.id} ------ #{org_member.profile.full_name}"
      elsif diff.empty?
        all_form += 1
      elsif diff.count == json_template_ids.count
        none_form +=1
      end
    end
    puts "Number of organization memberships all forms requested == #{all_form}"
    puts "Number of organization membership none forms requested == #{none_form}"
    puts "Total no organization memberships ==#{org_members.count} "
  end

  desc "find profile with multiple times form request"
  task find_multiple_form_requests: :environment do
    json_templates = JsonTemplate.in(_id: ENV['TemplateIds'].split()) + DocumentDefinition.where(name: "Photograph of child").to_a
    json_templates.each do |json_template|
     org_member =  json_template. notifications.map(&:organization_membership_id)
     org_member =  org_member.select{|element|  org_member.count(element) > 1 }.uniq
     puts "       ***--- #{json_template[:form_name] ||json_template[:name] } as  #{org_member.count } ---***      "
     OrganizationMembership.in(id: org_member).map(&:profile).each do |profile|
       puts" #{profile.id}--- #{profile.full_name}"
     end
    end
  end

  desc "verifying Duplicate Notifications only for requested state"
  task verify_duplicate_notifications: :environment do
    json_template_ids = ENV['TemplateIds'].split()
    notifications = Notification.in(json_template_id:  json_template_ids).desc(:created_at)
    count = 0
    notifications.each do |notification|
      scope = Notification.where(organization_membership_id: notification.organization_membership_id).requested.asc(:created_at)
      scope = scope.where(json_template_id: notification.json_template_id)  if notification.json_template
      scope = scope.where(document_definition_id: notification.document_definition_id) if notification.document_definition
      scope = scope.where(season_id: notification.season_id) unless notification.season_id.nil?
      # if count of notifications are greater than 1 (2 or more) then except this notification remove remaining
      if scope.count > 1
        puts "#{notification.organization_membership.profile.id} ------ #{notification.organization_membership.profile.full_name}"
        count+=1
      end
    end
    puts "    ***Info:  total #{count} duplicate notifications  in requested stated"
  end

  desc "removing multiple form requests"
  task remove_multiple_form_requests: :environment do
    json_templates = JsonTemplate.where(:workflow.ne=>"Application Form").to_a + DocumentDefinition.all.to_a
    json_templates.each do |json_template|
      org_member =  json_template.notifications.map(&:organization_membership_id)
      org_member =  org_member.select{|element|  org_member.count(element) > 1 }.uniq
      puts "       ***--- #{json_template[:form_name] ||json_template[:name] } as  #{org_member.count } ---***      "
      OrganizationMembership.in(id: org_member).each do |org_member|
        requested_state = org_member.notifications.where(json_template_id: json_template.id).requested
        submitted_state = org_member.notifications.where(json_template_id: json_template.id).submitted.asc(:created_at)
        if submitted_state.count >1
          requested_state.destroy_all
          submitted_state.offset(1).destroy_all
        elsif submitted_state.count ==1
          requested_state.destroy_all
        elsif requested_state.count >1
          requested_state.offset(1).destroy_all
        end
      end
    end
    puts "       ***--- Removed Sucessfully  ---***      "
  end


end