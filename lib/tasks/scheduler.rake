namespace :db do
  desc "Creates Alerts and Events dynamically to profiles based on AeDefinition"
  task :create_alerts_and_events=>:environment do
    #It is important to note that you should never be using the identity map when executing background jobs, rake tasks, etc
    Mongoid.unit_of_work(disable: :all) do
      AeDefinition.all.each do |ae_definition|
        #Get all the profiles exactly matched with zip_codes (later will need to geo coding)
        profiles = Profile.in(id: ae_definition.hospital.hospital_memberships.map(&:profile_id))#Profile.includes(:notifications).where(:kids_type.exists=>true)#.where(:"kids_type.zip".in=>ae_definition.zip_codes)
        profiles.each do |profile|
          # No need to create Notification if occurring_on date less than today(i.e;event/alert already passed away)
          if ae_definition.ad_hoc? #and ae_definition.occurring_on > Date.today
                                   #expiring_date = ae_definition.occurring_on # notification expires after occurring_on date
            ad_hoc_notification = AdHocNotification.new(is_accepted: 'requested',notification_type: ae_definition.definition_type,ae_definition_id: ae_definition.id)
            if ae_definition.to_whom.eql?('parent')
              profile.parent_profiles.each do |parent_profile|
                ad_hoc_notification.profile_id = parent_profile.id
                #Create Notification if this AeDefinition not exists already in profile's notifications
                ad_hoc_notification.save! unless parent_profile.notifications.where(ae_definition_id: ae_definition.id).exists?
              end
            else
              ad_hoc_notification.profile_id = profile.id
              #Create Notification if this AeDefinition not exists already in profile's notifications
              ad_hoc_notification.save! unless profile.notifications.where(ae_definition_id: ae_definition.id).exists?
            end
            ad_hoc_notification.unset(:category)
          elsif ae_definition.scheduled?
            #any Scheduled Event/Alert Occurs on Kids birthdate
            # check if kid is valid for this scheduled event/alert based on occurring_days
            # for ex:  Event will occurring on 45 days after the kid birthdate(age) ,here no need to create notification if kid age is 46 days or more and less than due_by_days
            # age between occurring_days and (occurring_days+ due_by_days)
            unless parent_profile.notifications.where(ae_definition_id: ae_definition.id).exists?
              age_in_days = profile.kids_type.age_in_days
              if age_in_days.between?(ae_definition.occurring_days, (ae_definition.occurring_days+ae_definition.due_by_days))
                expiring_date = Date.today + ae_definition.due_by_days # will expiring_on from today(this notification created date) to due_by_days
                ScheduleNotification.create!(is_accepted: 'requested',notification_type: ae_definition.definition_type,
                                             ae_definition_id: ae_definition.id,profile_id: profile.id,expiring_on: expiring_date).unset(:category)
              end
            end
          end

        end
      end
    end
    GC.start # start immediately the garbage collection
  end
end