class Weblink
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  
  embedded_in :organization
  #embedded_in :hospital

  field :link_name, :type => String
  field :link_url, :type => String
  field :link_description, :type => String

  scope :recent, limit(4).desc(:created_at)
end
