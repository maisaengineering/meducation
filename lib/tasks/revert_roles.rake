namespace :db do
  desc "Assigns the roles to Role collection from memberships"
  task :revert_roles => :environment do
    user = User.create fname: 'Super Admin', email: 'superadmin@maisasolutions.com', password: '123456', password_confirmation: '123456'
    user.create_role(:super_admin)
    memberships = Membership.all
    org_count ,parent_count = 0,0
    memberships.each do |membership|
      membership.roles.each do |m_role|
        user = User.where(id: membership.user_id).first
        if user
          case m_role.role
            when 'organization'
              user.create_role(:org_admin,[m_role.organization])
              org_count += 1
            when 'parent'
              user.create_role(:parent)
              parent_count += 1
          end
        else
          puts "INFO:  User not found for Id- #{membership.user_id} Role : #{m_role.role}"
        end
      end
    end
    #Membership.delete_all ,if no need
    puts "############  Total #{org_count} OrgRoles created and Total #{parent_count} Parent Roles created out of #{memberships.count}"
  end
end