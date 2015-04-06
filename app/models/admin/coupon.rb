class Admin::Coupon
  include Mongoid::Document
  field :name, :type => String
  field :discount, :type => Integer
  field :coupon_type, :type => String 
  field :season, :type => Integer
  field :organization_id, :type => Integer
  field :season_id, :type => Integer


  belongs_to :organization, :class_name => "Organization"

  validates_uniqueness_of :name, :message => "ERROR: It's already taken"

  #remove leading and trailing whitespace
  before_validation { |record| self.name = self.name.strip }

end
