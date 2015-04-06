class NormalNotification < Notification
  include Mongoid::Attributes::Dynamic
  public_class_method :new

  field :is_accepted ,:type => String, :default => 'Application submitted'
  field :category, default: CATEGORIES[:form]

end
