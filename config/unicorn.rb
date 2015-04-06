# config/unicorn.rb
worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
timeout 60

# Mongoid advises not to use preload_app
# - http://mongoid.org/docs/upgrading.html
# - http://mongoid.org/docs/rails/railties.html
#preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  #defined?(ActiveRecord::Base) and  ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end
  # defined?(ActiveRecord::Base) and  ActiveRecord::Base.establish_connection

  # for memcached/DalliStore, to reset/reconnect connection
  # Rails.cache.reset
end