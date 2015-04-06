class FeedEntry
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :title
  field :author
  field :url
  field :content
  field :published
  field :summary

  embedded_in  :feed
 default_scope  desc(:published)

end
