class ScheduledAeDefinition < AeDefinition
  include Mongoid::Attributes::Dynamic

  public_class_method :new
  #Attributes & Variables -----------------

  #Fields ---------------------------------
  field :occurring_days ,type: Integer
  field :due_by_days ,type: Integer
  #Relations ------------------------------

  #Scopes ---------------------------------

  #Index(es) ------------------------------

  #Validations goes here ------------------
  validates :occurring_days,:due_by_days ,presence: true ,numericality: {only_integer: true}
  #Callbacks goes here --------------------


  #Class Methods goes here-----------------

  #Instance Methods -----------------------
end