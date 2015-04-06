class MembershipEnrollment
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :season
  
  field :family_currently_enrolled, :type => String
  field :active_member_of_ppc, :type => String
  field :age_group_and_school_days, :type => String

  # NEW FIELD FOR PECHTREE 
  field :secondary_choice_of_class_days, :type => String
  field :are_you_enrolling_siblings, :type => String
  field :sibling_name, :type => String
  field :sibling_age, :type => String
  field :sibling_days, :type => String
end
