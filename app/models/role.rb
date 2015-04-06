# Present we have roles ['Super Admin','Org Admin','Hospital Admin','Parent']
# for Parent,Super Admin no need to assign ref_ids
class Role
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  #--------  Fields
  field :user_id
  field :name
  field :ref_ids,type: Array
  #--------- Attributes & Variables
  NAMES = {super_admin: 'Super Admin',org_admin: 'Org Admin',parent: 'Parent'}

  index({name: 1})
  index({user_id: 1})
  #--------- Relations
  belongs_to :user , touch: true

  #--------- Scopes

  #--------- Validations
  validates :name,presence: true ,uniqueness: {scope: :user_id}
  validates :user_id,presence: true
  #--------  Callbacks
 # before_save {|record| record.ref_ids = ref_ids.uniq}

  #--------  Class Methods

  #--------  Instance Methods


end

