class Invitation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  STATUS=  {invited:"INVITED", accepted: "ACCEPTED", }

  field :status, default: STATUS[:invited]
  field :token, type: String
  field :email

  belongs_to :profile

  validates :token, presence: true,uniqueness: true
  validates :email, presence: true, uniqueness: { scope: :profile_id,message: "Already sent invitation to this Email Id." }

  before_validation :email_to_downcase
  before_validation :generate_token , only: :create
  after_create :send_invitation

  private

  def generate_token
    self.token = Digest::MD5.hexdigest(Time.now.to_s)
  end

  def email_to_downcase
    self.email = email.downcase
  end

  def send_invitation
    Notifier.delay.invite_mom(self)
  end

end
