module ConnectToGridFilesystem
  def grid_filesystem_connection
    if Rails.env.production?
      require 'uri'
      db = URI.parse(ENV['MONGOHQ_URL'])
      db_name = db.path.gsub(/^\//, '')
      db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
      db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.user.nil?)
      Mongo::GridFileSystem.new(db_connection)
    else
      Mongo::GridFileSystem.new(Mongo::Connection.new.db(Mongoid.default_session.options[:database]))
    end
  end
end
