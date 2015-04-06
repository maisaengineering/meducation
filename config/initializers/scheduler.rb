require 'rubygems'
require 'rufus-scheduler'
require 'rake'

scheduler = Rufus::Scheduler.new(:lockfile => ".rufus-scheduler.lock")

unless scheduler.down?
  Rails.logger.info "Schedular state...#{ENV['SCHEDULER_ENABLE']}"

  if ENV['SCHEDULER_ENABLE'].eql?("true")

    scheduler.cron("0 16 * * *") do
      Delayed::Job.enqueue InvitationReminder.new(nil, nil), queue: 'inv_reminder'
      Delayed::Job.enqueue EmailReminders::SigninReminder.new(2), queue: 'second_signin_reminder'
    end

    scheduler.cron("45 23 * * *") do
      Delayed::Job.enqueue EmailReminders::SigninReminder.new(3), queue: 'third_signin_reminder'
    end

    scheduler.cron("0 12 * * sun") do
      Delayed::Job.enqueue EmailReminders::WeeklyActivityDigest.new, queue: 'weekly_activity_digest'
    end

    scheduler.every '4h' do
      #It is important to note that you should never be using the identity map when executing background jobs, rake tasks, etc
      AeDefinition.active.each do |ae_definition|
        #Get all the profiles exactly matched with zip_codes (later will need to geo coding)
        profiles = Profile.in(id: ae_definition.hospital.hospital_memberships.map(&:profile_id))
        other_parents = Hash[Profile.collection.aggregate({"$unwind"=>"$parent_type.profiles_manageds"},
                                                          {"$match"=>{"parent_type.profiles_manageds.kids_profile_id"=>{"$in"=>profiles.map(&:created_kids_ids).flatten.map(&:to_s)},
                                                                      "parent_type.profiles_manageds.manageable"=>true}},
                                                          {"$group"=>{_id:"$parent_type.profiles_manageds.kids_profile_id", parent_ids:{"$push"=> "$_id"} }}).map(&:values)]
        profiles.each do |profile|
          # No need to create Notification if occurring_on date less than today(i.e;event/alert already passed away)
          #any Scheduled Event/Alert Occurs on Kids birthdate
          #  # check if kid is valid for this scheduled event/alert based on occurring_days
          #  # for ex:  Event will occurring on 45 days after the kid birthdate(age) ,here no need to create notification if kid age is 46 days or more and less than due_by_days
          #  # age between occurring_days and (occurring_days+ due_by_days)
          begin
            if ae_definition.to_whom.eql?('parent')
              if ae_definition.ad_hoc? and !profile.notifications.where(ae_definition_id: ae_definition.id).exists?
                AdHocNotification.create(profile_id:profile.id, is_accepted: 'requested',
                                         notification_type: ae_definition.definition_type,
                                         ae_definition_id: ae_definition.id).unset(:category)
              end
            else
              profile.created_kids.each do |kid_profile|
                other_parents[kid_profile.id.to_s].each do |parent_id|
                  unless kid_profile.notifications.any_of({:is_accepted.ne=> 'requested', :parent_id.exists=> false},
                                                          {parent_id: parent_id}).and(ae_definition_id: ae_definition.id).exists?
                    if ae_definition.ad_hoc?
                      AdHocNotification.create(profile_id:kid_profile.id, is_accepted: 'requested', parent_id: parent_id,
                                               notification_type: ae_definition.definition_type,
                                               ae_definition_id: ae_definition.id).unset(:category)

                    elsif ae_definition.scheduled?
                      age_in_days = kid_profile.kids_type.age_in_days
                      if age_in_days.between?(ae_definition.occurring_days, (ae_definition.occurring_days+ae_definition.due_by_days))
                        expiring_date = Date.today + ae_definition.due_by_days # will expiring_on from today(this notification created date) to due_by_days
                        ScheduleNotification.create!(profile_id: kid_profile.id, is_accepted: 'requested', parent_id: parent_id,
                                                     notification_type: ae_definition.definition_type,
                                                     ae_definition_id: ae_definition.id, expiring_on: expiring_date).unset(:category)
                      end
                    end
                  end
                end
              end
            end
          rescue
            next
          end

        end
      end
    end
    #TODO We are commenting this code as we are not sharing milestones from web to Facebook. Need to uncomment it when ever needed.
    # scheduler.every '24h' do
    #   milestones =  Milestone.where(snapshot_created: false)
    #   handlebars = Handlebars::Context.new
    #   handlebars.register_helper(:ifEqual) do |context, v1,v2, block|
    #     v1===v2 ? block.fn(context) :  block.inverse(context)
    #   end
    #   milestones.each do |milestone|
    #     begin
    #       img_content = milestone.milestone_template.designs.find(milestone.design_id).content.split(";")
    #       img_design = img_content.reject{|word| word.include?('-transform') and !word.include?('text')}.join(';')
    #       file = Tempfile.new([milestone.milestone_template.name, '.png'], 'tmp', encoding: 'ascii-8bit')
    #       template = handlebars.compile(img_design)
    #       kid_profile = milestone.profile
    #       parent_profile = kid_profile.parent_profiles.first
    #       hospital_membership = parent_profile.hospital_memberships.first
    #       hospital = hospital_membership.hospital rescue nil
    #       data_points = {context: 'large',firstName: kid_profile.kids_type.fname,lastName: kid_profile.kids_type.lname,nickName: kid_profile.kids_type.nickname}
    #       data_points.merge!({date: milestone.milestone_date.try(:strftime, '%B %d, %Y'),
    #                           additionalText: milestone.additional_text,journalEntry: milestone.journal_entry,
    #                           photo: (milestone.mobile_url.blank?? nil : milestone.mobile_url << "?" << milestone.updated_at.to_i.to_s)
    #                          })
    #       data_points.merge!(mPersisted: true)
    #       data_points.merge!({hospitalLogo: hospital.logo2.url}) if hospital and hospital.logo2
    #       data_points.merge!({hospitalOptedOut: !hospital_membership.nil? ? hospital_membership.is_opt_out : true})
    #       data_points.merge!({logo: ActionController::Base.helpers.asset_path('logo.png')})
    #       kit = IMGKit.new(template.call(KIDSLINK: data_points).html_safe, height: 660, width: 465, quality: 100)
    #       kit.stylesheets << "#{Rails.root}/app/assets/stylesheets/rb_set1.css"
    #       file.write(kit.to_png)
    #       file.flush
    #       milestone.snapshot = file
    #       milestone.snapshot_created = true
    #       milestone.save
    #     rescue
    #       # user uploaded milestone_image and its not present in S3(may be due to fog_directory changed or renamed), so update of milestone_image will be failed
    #       Rails.logger.error "Failed to generate snapshot for milestone(id) : #{milestone.id}"
    #     ensure
    #       file.unlink if file
    #     end
    #   end
    # end
  end
end
# #Type in cmd(terminal) ---# man 5 crontab
# #   * * * * *  --- total 5 stars indicates with order-->  Min Hour Day Month WeekDay
# #-- In detail ------------------#
# #  field          allowed values
# #  -----          --------------
# #  minute         0-59
# #  hour           0-23
# #  day of month   1-31
# #  month          1-12 (or names, see below)
# #  day of week    0-7 (0 or 7 is Sun, or use names)
#
# #Ex:  scheduler.cron("5 15 * * sun") do ;end --> every tue 15:03 PM -->every sun afternoon at 3 hours and 5 mins it will run
# #Ex:  scheduler.cron("30 10 * * sat") do ;end --> every sat 10:30 AM -->every sun morning at 10 hours and 30 mins it will run
#
# #every wed 00:01 Am