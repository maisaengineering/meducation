class AgeValidity
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :start, type: Integer
  field :end,   type: Integer
  validates :start , numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: :end } ,allow_blank: true
  validates :end,  numericality: { greater_than_or_equal_to: :start },allow_blank: true

end