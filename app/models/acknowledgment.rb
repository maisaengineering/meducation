class Acknowledgment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  belongs_to :user

  field :kids_id, :type => String
  field :season, :type => String
  field :user_id, :type => String
  field :user_name, :type => String
  field :form_id, :type => String
  field :org_id, :type => String
  field :acknowledgment_name, :type => String
  field :acknowledgment_at, :type => Date


  def user
    User.find(user_id) rescue nil
  end
  
end
