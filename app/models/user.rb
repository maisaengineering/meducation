class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic


  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :timeoutable#, :token_authenticatable

  #attr_accessible :fname,:lname, :email, :password, :password_confirmation, :remember_me#, :confirmation_token, :confirmed_at, :confirmation_sent_at, :unconfirmed_email

  validates_presence_of :email, :message => "ERROR: Email Can't be blank"
  validates_uniqueness_of :email,     :case_sensitive => false, :allow_blank => true, :if => :email_changed?, :message => "ERROR: Email already exists."
  validates_format_of :email, :with  => Devise.email_regexp, :allow_blank => true, :if => :email_changed?, :message => "ERROR: Email format not valid"
  validates_presence_of :password, :message => "ERROR: Password Can't be blank"
  validates_presence_of :password_confirmation, :message => "ERROR: Password confirmation Can't be blank"
  validates_confirmation_of :password, :message => "ERROR: Password mismatch"
  validates_length_of :password, :within => Devise.password_length, :allow_blank => true, :message => "ERROR: Password should be atleast 6 characters"

  has_many :memberships, dependent: :delete
  has_many :acknowledgments, dependent: :delete
  has_many :roles, dependent: :delete
  ## Database authenticatable
  field :email,              :type => String, :default => ""
  field :encrypted_password, :type => String, :default => ""
  field :fname,               :type => String
  field :lname,               :type => String
  field :phone_home, :type => Integer
  field :phone_work, :type => Integer
  field :phone_mobile, :type => Integer

  ## Recoverable
  field :reset_password_token,   :type => String
  field :reset_password_sent_at, :type => Time

  ## Rememberable
  field :remember_created_at, :type => Time

  ## Trackable
  field :sign_in_count,      :type => Integer, :default => 0
  field :current_sign_in_at, :type => Time
  field :last_sign_in_at,    :type => Time
  field :current_sign_in_ip, :type => String
  field :last_sign_in_ip,    :type => String

  # Confirmable
  field :confirmation_token,   :type => String
  field :confirmed_at,         :type => Time
  field :confirmation_sent_at, :type => Time
  field :unconfirmed_email,    :type => String # Only if using reconfirmable

  field :active, :type => Mongoid::Boolean, :default => false
  ## Lockable
  # field :failed_attempts, :type => Integer, :default => 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    :type => String # Only if unlock strategy is :email or :both
  # field :locked_at,       :type => Time

  ## Token authenticatable
  # field :authentication_token, :type => String

  attr_accessor :address#, :referral_code, :verified_phone_number
  before_save :strip_whitespace


  # index(es)
  index({ email: 1 }, { unique: true, background: true })

  def strip_whitespace
    [:fname,:lname].each do |attr|
      self.send "#{attr}=" , self.send(attr).try(:strip)
    end
  end

  def active_for_authentication?
    super #&& account_active?
  end

  def account_active?
    self.active == true
  end

  # Returns parent profile if user has_role?(:parent)
  def parent_profile
    @parent_profile ||= Profile.where("parent_type.email"=> email).first #if has_role?(:parent)
  end

  #returns all the kid profile managing by this user if has_role?(:parent)
  def managed_kids
    Profile.in(id:managed_kids_ids).asc('kids_type.birthdate')
  end


  ##--------- Role related methods

  def cached_roles
    Rails.cache.fetch([self, "roles"]) { roles.to_a }
  end

  #--- checks if user has role for given parameter
  #ex: user.has_role?(:parent) --> true or false
  def has_role?(role)
    roles.where(name: Role::NAMES[role]).exists?
    #cached_roles.map(&:name).include?(Role::NAMES[role])
  end

  #-- returns all the managing organizations if has_role?(:org_admin)
  def managed_organizations
    if has_role?(:org_admin)
      org_ids = roles.where(name: Role::NAMES[:org_admin]).first.ref_ids
      Organization.in(id: org_ids)
    else
      []
    end
  end

  #-----------------------------------------------------
  #Creates a unique role for a user with ref_ids
  #Ex: user.create_role(:super_admin) ->checks if has already role if not creates
  #Ex: user.create_role(:org_admin,[org_id1,org_id1]) ->checks if has already role org_admin if found assigns the org_ids

  def create_role(role,ref_ids = nil)
    if has_role?(role)
      if ref_ids
        role = roles.where(name: Role::NAMES[role]).first
        role.ref_ids = (role.ref_ids + ref_ids).uniq
        role.save
      else
        roles.find_or_create_by(name: Role::NAMES[role])
      end
    else
      ref_ids.nil? ?  roles.create(name: Role::NAMES[role]) : roles.create(name: Role::NAMES[role],ref_ids: ref_ids)
    end
  end

  def add_kid(params)
    kid =Profile.create(kids_type: params)
    unless kid.errors.any?
      parent =Profile.where("parent_type.email"=>self.email).first
      pm= parent.parent_type.profiles_manageds.first
      relationship = pm ? pm.child_relationship : nil
      parent.parent_type.profiles_manageds.create(child_relationship: relationship,
                                                  kids_profile_id: kid.id,
                                                  manageable: true, created: true)
    end
    return kid
  end

  #def opting_partner_branding(params)
  #  if params.eql?(true)
  #    hospital_memberships = HospitalMembership.deleted.in(profile_id: @parent_profile.id)
  #    hospital_memberships.map(&:restore) unless hospital_memberships.empty?
  #  else
  #    hospital_memberships = @parent_profile.hospital_memberships
  #    hospital_memberships.map(&:destroy) unless hospital_memberships.empty?
  #  end
  #end
  #
  # def opting_partner_from_milestone(params)
  #   unless params.to_s.blank?
  #     if params.is_a?(Boolean)
  #       hospital_memberships = parent_profile.hospital_memberships
  #       hospital_memberships.each{|hm| hm.update_attributes(is_opt_out: params)} unless hospital_memberships.empty?
  #     else
  #       errors["onboard_partner_opt_out"]= "ERROR:onboard_partner_opt_out value Should be Boolean"
  #     end
  #   end
  # end

  def opting_ae_notification_emails(params)
    unless params.to_s.blank?
      if params.is_a?(Boolean)
       parent_profile.parent_type.update_attributes(ae_notification_opt_out: params)
      else
        errors["non_essential_emails_opt_out"]= "ERROR: non_essential_emails_opt_out value Should be Boolean"
      end
    end
  end



  def all_parents
    unless managed_kids_ids.blank?
      Profile.elem_match(:"parent_type.profiles_manageds"=>{:kids_profile_id.in=>managed_kids_ids.map(&:to_s),
                                                            manageable: true}).asc(:_id)
    else
      Profile.where("parent_type.email"=> email)
    end
  end

  def self_and_managed_kids_profiles
    Profile.any_of({:id.in=> managed_kids_ids},{id: parent_profile.id})
  end

  def family_profiles
    unless managed_kids_ids.blank?
      Profile.any_of({:id.in=> managed_kids_ids},{:"parent_type.profiles_manageds.kids_profile_id".in=>managed_kids_ids})
    else
      Profile.where("parent_type.email"=> email)
    end
  end

  private

  def profile
    Profile.where("parent_type.email"=>self.email).first
  end

  def managed_kids_ids
    parent_profile.managed_kids_ids
  end

end
