class ParentProfile < ProfileType
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :email, :type => String
  field :parent_id, :type => String
  
  embedded_in :profile
  embeds_many :phone_numbers
  embeds_many :profiles_manageds
end
