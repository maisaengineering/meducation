class ProfileOrg
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Mongoid::Attributes::Dynamic

  belongs_to :profile
  embeds_many :org_seasons
end
