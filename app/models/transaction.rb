class Transaction
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :transaction_id, :type => String
  field :type, :type => String
  field :amount, :type => String
  field :status, :type => String
  field :fname, :type => String
  field :lname, :type => String
  field :email, :type => String
  field :address, :type => String
  field :city, :type => String
  field :state, :type => String
  field :zip, :type => String
  field :coupon, :type => String
  # Newly added
  field :organization_id, :type => String
  field :user_id, :type => String
  field :profile_id, :type => String #kid id
  field :season_year, :type => String

  #Relations
  belongs_to :organization
  belongs_to :user


end

