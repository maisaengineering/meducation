class Session
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  
  embedded_in :season
  
  field :session_name, :type => String
  field :session_open, type: String,default: '1'
end
