class MultiMediaMetaData
  include Mongoid::Document
  # Fields -------------------------------
  field :exif
  field :key
  field :processing

  belongs_to :target, polymorphic: true

  before_save do |record|
    record.unset(:key) if record.key.blank?
  end

end