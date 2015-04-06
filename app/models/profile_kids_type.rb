class ProfileKidsType < ProfileType
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  include Mongoid::Timestamps::Updated
  include Mongoid::Attributes::Dynamic

  #field :status, :type => String, :default => "inactive"
  has_many :organization_memberships
  embedded_in :profile,class_name: 'Profile', :inverse_of => :kids_type
  embeds_many :phone_numbers

  #after_initialize :initailize_date  commented - method override in org enrolle page

  # Fields -----------------------------------
  field :kids_id
  field :fname
  field :lname
  field :birthdate#,type: Date,default: nil
  field :nickname


  attr_accessor :address1, :address2, :state, :city, :zip, :managed_by, :photo_id, :address

  # Callbacks --------------------------------
  before_create :generate_unique_kids_id
  before_save :add_meta_data_to_membership
  before_save :strip_whitespace

  #Save Birthdate type as Date,so Parse String into Date
  before_validation do
    self.birthdate = Date.strptime(birthdate, "%m/%d/%Y")  if birthdate.present? and  birthdate.is_a?(String)
  end

  def m_birthdate=(value)
    self.birthdate = Date.strptime(value, "%Y-%m-%d").strftime("%m/%d/%Y")
  end

  def add_meta_data_to_membership
    if fname_changed? or lname_changed? or birthdate_changed? or nickname_changed?
      profile.organization_memberships.only(:meta_data).each do |org_membership|
        meta_data = org_membership.meta_data
        meta_data.update_attributes(fname: fname,fname_downcase: fname.downcase,
                                    lname: lname,lname_downcase: lname.downcase,
                                    nickname: nickname,nickname_downcase: nickname.downcase,birthdate: birthdate)
      end
    end
  end

  def strip_whitespace
    [:fname,:lname,:nickname,:mname].each do |attr|
      (self.send "#{attr}=" , self.send(attr).try(:strip)) if respond_to?(attr)
    end
  end


  def generate_unique_kids_id
    #TODO below is not a correct way to generate unique code
    unless self.kids_id.present?
      charset = %w{ 0 1 2 3 4 5 6 7 8 9 }
      self.kids_id =  "KL#{(0...6).map{ charset.to_a[rand(charset.size)] }.join}"
    end
  end

  def name
    "#{fname} #{lname}"
  end

  def initailize_date
    self.created_at = DateTime.now
    self.updated_at = DateTime.now
  end

  def to_hash
    hash = {}; self.attributes.each { |k,v| hash[k] = v }
    return hash
  end

  def safe_attr_hash
    to_hash.delete_if {|k, v| ['_id', '_type', 'created_at', 'updated_at'].include? k }
  end

  def coll_hash
    hash = {}; att = Array.new(); self.attributes.each { |k,v| hash[k] = v and att.push(k)  }
    return hash, att
  end

  def new_attr_hash(exit_att)
    kids_data , kids_att = coll_hash
    kids_data.delete_if {|k, v|  exit_att.include? k }
  end

  def safe_att_hash
    to_hash.delete_if {|k, v| ['_id', '_type', 'created_at', 'updated_at','acknowledge_by'].include? k }
  end

  # For version 1 -old production data birthdate is saved as Time(DataType),
  # For version 2 -production data birthdate is saved as String,so compare with both
  def age_in_days
    (Date.today - birthdate.to_date).to_i
  end


end


