class Category
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Tree

  include Mongoid::Attributes::Dynamic

  #--------- Attributes & Variables

  #Fields
  field :name, type: String

  #--------- Relations
   has_many :documents
  #Scopes ------------------
  #default_scope asc(:created_at)
  scope :middle, where(:align_side.exists=>false)
  scope :left, where(:align_side.exists=>true)
  scope :positioned, asc(:position).offset(1)

  #Indexes ------------------
  index({ name: 1, align_side: 1,  parent_id: 1})
  index({ parent_ids: 1 },{ background: true })

  #--------- Validations goes here
  validates :name, presence:true
  #--------  Callbacks goes here
  #---------  Class Methods goes here

  #---------- Instance Methods
  def display_name
    displayname = (!self.root? and self.name.eql?(parent.name)) ? "(General) #{name}" : self.name

    if displayname.include?("(#{self.root.name.to_s.downcase})")
      displayname.gsub(" (#{self.root.name.to_s.downcase})",'')
    elsif displayname.include?("(#{self.root.name})")
      displayname.gsub(" (#{self.root.name})",'')
    else
      displayname
    end
  end

end
