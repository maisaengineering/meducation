#Each Milestone Template has many attachments.
#From edit page copy the s3 url of attachment and use it in content of milestone template
class TemplateImage
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  embedded_in :milestone_template, inverse_of: :template_images

  mount_uploader :source, ImageUploader  ,dependent: :destroy

  # Validations


end
