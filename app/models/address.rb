class Address
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Geocoder::Model::Mongoid
  include Mongoid::Timestamps

  field :address1, :type => String
  field :address2, :type => String
  field :city, :type => String
  field :state, :type => String
  field :country, :type => String
  field :zipcode, :type => String
  field :geo, type: Array
  geocoded_by :zipcode, coordinates: :geo

  #Validations --------------------------------------------------------------------------------
  validates :zipcode, presence: true, if: -> (address) {address.country=='US' }

  #Associations----------------------------------------------------------------------------
  belongs_to :profile, index:true

  before_save :geocode, if: Proc.new { |address| address.zipcode?}

  def zip=(value)
    self.zipcode = value
  end

  def zip
    self.zipcode
  end



end
