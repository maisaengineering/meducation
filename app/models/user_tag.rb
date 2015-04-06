class UserTag
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic

  field :category_ids, type: Array
  field :tag

  embedded_in :profile

  validates :tag, presence: true, uniqueness: { scope: :profile_id}

  def display_name
    tag
  end

  def name
    tag
  end

  def root
    Category.in(id: category_ids).first
  end

  def root?
    false
  end

  def children
    []
  end

end
