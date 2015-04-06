namespace :clear do
  desc "Expires the page cache(landing page)"
  task :page_cache => :environment do
    ActionController::Base::expire_page("/")
    Rails.logger.info("Removed landing page cache")
  end
end
