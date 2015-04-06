class HolidayValidity
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :start, type: Date
  field :end,  type: Date
  #validates_presence_of :start, :end
end