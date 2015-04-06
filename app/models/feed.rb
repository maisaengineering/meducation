class Feed
  include Mongoid::Document
  include Mongoid::Timestamps
  include Geocoder::Model::Mongoid
  include Mongoid::Attributes::Dynamic

  field :title
  field :url
  field :author
  field :city
  field :state
  field :frequency , type: Float
  field :notes
  field :is_default, type: Mongoid::Boolean, default: false
  field :zipcodes, type: Array
  field :geo, :type => Array

  embeds_many :feed_entries

  geocoded_by :address , :coordinates => :geo

  before_save :geocode
  after_create :parse_rss_feeds

  def address
    [city, state].compact.join(', ')
  end

  def parse_rss_feeds
    feed_entries.destroy_all
    feed =   Feedzirra::Feed.fetch_and_parse(url)
    add_entries(feed.entries)
    Delayed::Job.enqueue RssFeedUpdate.new(feed, self, self.frequency), :run_at=>self.frequency.hours.from_now
  end

  def add_entries(entries)
    entries.each do |entry|
      feed_entries.create(title: entry.title,
                               author: entry.author,
                               url: entry.url,
                               content: entry.content,
                               published: entry.published,
                               summary: entry.summary)
    end
  end
end

