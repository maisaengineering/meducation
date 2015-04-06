class PhoneNumber
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  
  embedded_in :profile_parent_type
  embedded_in :parent_profile
  embedded_in :profile_kids_type
  embedded_in :organization_membership
  embedded_in :season

  # as_enum :type, [:mobile, :home, :work], :prefix => true
  
  field :type, :type => String
  field :contact, :type => String

end
