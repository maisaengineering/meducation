class ProfileParentType < ProfileType
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  
  field :email, :type => String
  field :fname, :type=>String
  field :lname, :type=>String
  # field :parent_id, :type => String
  field :ae_notification_opt_out, type: Mongoid::Boolean, default: false
  field :org_notification_opt_out, type: Mongoid::Boolean, default: false

  attr_accessor :referral_code, :photo_id, :address, :password, :password_confirmation#, :verified_phone_number

  embedded_in :profile, :inverse_of => :parent_type
  embeds_many :profiles_manageds
  embeds_many :phone_numbers

  after_save {|record| record.unset(:child_relationship) if record.respond_to?(:child_relationship)}
  after_save :assign_parent_role
  before_save :downcase_email
  before_save :strip_whitespace

  accepts_nested_attributes_for :phone_numbers

  def assign_parent_role
    user = User.where(email: self.email).first
    user.create_role(:parent) if user
  end

  def downcase_email
    write_attribute(:email_dis,email) if email.present?
    write_attribute(:email,email.downcase) if email.present?
  end

  def strip_whitespace
    [:fname,:lname,:mname].each do |attr|
      (self.send "#{attr}=" , self.send(attr).try(:strip)) if respond_to?(attr)
    end
  end

  def to_hash
    hash = {}; self.attributes.each { |k,v| hash[k] = v }
    return hash
  end

  def safe_attr_hash
    to_hash.delete_if {|k, v|  ['_id', '_type'].include? k }
  end

end
