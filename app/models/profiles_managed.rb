class ProfilesManaged
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  
  embedded_in :parent_type, :class_name => "ProfileParentType"
  embedded_in :parent_profile
  
  #as_enum :managed_profile_type, [:father, :mother], :prefix => true
    
  field :kids_profile_id, :type => String
  field :child_relationship, :type => String
  field :manageable, type: Mongoid::Boolean, default: false
  #to identify the creator of the kid
  field :created, type: Mongoid::Boolean, default: false

  attr_accessor :current_user

  validates :kids_profile_id, presence:true, uniqueness:true

  before_validation :assign_relationship, if: Proc.new{|pm| pm.child_relationship.blank?}
  before_update :make_other_parent_as_creator, if: Proc.new{|pm| pm.created and pm.manageable_changed? and !pm.manageable }
  after_update :reload_managed_kids, if: Proc.new{|pm| pm.manageable_changed?}
  after_save :create_user, if: Proc.new{|pm| !pm.current_user.blank? and pm.manageable }


  def assign_relationship
    sibling_relation = parent_type.profiles_manageds.map(&:child_relationship).reject(&:blank?).first
    self.child_relationship =  sibling_relation || 'Mother'
  end

  def kid_profile
    @kid_profile ||= Profile.find(kids_profile_id)
  end

  private

  def create_user
    parent= self.parent_type
    user= User.where(email: parent.email).first
    if user.nil?
      new_pwd = Profile.generate_activation_code
      user= User.create(email:parent.email , fname:parent.fname,
                        password: new_pwd, password_confirmation: new_pwd)
      unless user.errors.any?
        user.create_role(:parent)
        kids_name = user.managed_kids.map(:nickname)
        Notifier.delay.signup_additional_confirmation(kids_name, current_user[:fname],
                                                      current_user[:lname], new_pwd,
                                                      user.email, kids_name)
      end
    end
  end

  def reload_managed_kids
    self.parent_type.profile.managed_kids_ids_reload
  end

  #--- when creator don't want to manage kid, then we make other parent who is longer time with kidslink  as the creator of kid
  def make_other_parent_as_creator
    other_parent= Profile.elem_match(:"parent_type.profiles_manageds"=>{kids_profile_id: kids_profile_id, :created.ne=>true,
                                                                        manageable: true}).asc(:created_at).first
    if other_parent
      pm= other_parent.parent_type.profiles_manageds.find_by(kids_profile_id: kids_profile_id)
      pm.set(created: true) if pm
      unset(:created)
    end
  end


end
