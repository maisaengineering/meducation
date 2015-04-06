#--
# Metadata can embed into any model
# For example we can embed this into organization_membership to include fname,lname,birthdate
# Similarly we can embed this into any model for saving data
#++
class MetaData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  #-------- Fields
  # all the attributes are dynamic
  #--------- Attributes & Variables

  #--------- Relations
  embedded_in :organization_membership
  embedded_in :profile

  #--------- Scopes

  #--------- Validations

  #-------- Callbacks

  #--------- Class Methods

  #---------- Instance Methods

end