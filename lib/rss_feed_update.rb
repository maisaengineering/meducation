class RssFeedUpdate < Struct.new(:feed, :feeds_class, :interval)
  def perform
    updated_feed = Feedzirra::Feed.update(feed)
    feeds_class.add_entries(feed.new_entries) unless  updated_feed.blank?
    feed = Feedzirra::Feed.fetch_and_parse(feeds_class.url)
    Delayed::Job.enqueue RssFeedUpdate.new(feed, feeds_class, interval ), :run_at=>interval.hours.from_now
  end
end