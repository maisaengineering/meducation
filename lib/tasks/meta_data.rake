#---------------------------------
# Date Jul 2,2013
# This tasks adds fname,lname,nickname,birthdate to organization_membership as metadata
#----------------------------------
namespace :db do
  desc "Adds the metadata(fname,lname,nickname)"
  task add_meta_data_to_org_membership: :environment do
    #It is important to note that you should never be using the identity map when executing background jobs, rake tasks, etc
    Mongoid.unit_of_work(disable: :all) do
      organization_memberships = OrganizationMembership.includes(:profile).all
      count = 0
      organization_memberships.each do |org_membership|
        profile = Profile.find(org_membership.profile_id) rescue nil
        if profile
          if profile.kids_type
            kids_type = profile.kids_type
            if org_membership.create_meta_data(fname: kids_type.fname,fname_downcase: kids_type.fname.downcase,
                                               lname: kids_type.lname,lname_downcase: kids_type.lname.downcase,
                                               nickname: kids_type.nickname || kids_type.fname,nickname_downcase: kids_type.nickname.downcase || kids_type.fname.downcase,
                                               birthdate: kids_type.birthdate,kid_profile_created_at: kids_type.created_at)
              count += 1
            end
          else
            puts "WARN: Profile Is Not a KidsType for : #{org_membership.profile_id}"
          end
        else
          puts "WARN: Profile Not found for : #{org_membership.profile_id}"
        end
      end
      puts "INFO: Total metadata #{OrganizationMembership.count}/#{count}"
    end
  end
end