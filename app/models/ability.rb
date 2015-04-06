class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
    user ||= User.new # guest user (not logged in)
    roles = user.roles.only(&:name).map(&:name).map(&:parameterize).map(&:underscore).map(&:to_sym)
    if roles.include?(:super_admin)
      can :manage ,:all
      can :manage ,Organization
      can :manage ,Admin::Coupon
      #cannot [:top_dashboard],Profile #donot access the parent dashboard
    elsif user.has_role?(:org_admin)
      can :manage ,Organization ,id: user.managed_organizations.map(&:id)
      can :manage ,DocumentDefinition #,organization_id: user.managed_organizations.map(&:id)
      cannot [:index,:new,:create,:destroy],Organization
      #cannot [:top_dashboard],Profile #donot access the parent dashboard
    else
      can :manage,:all
      cannot :manage ,Organization
      cannot :manage ,DocumentDefinition
      cannot :manage ,Admin::Coupon
      cannot :manage ,AeDefinition
      cannot :manage ,Feed
      can [:profile_request],Organization
    end
  end
end
