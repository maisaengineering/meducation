class Membership
  include Mongoid::Document

  embeds_many :roles

  belongs_to :user
end