class LookUp
  class << self
    def sessions(org,season_id)
      begin
        organization = Organization.find(org)
        sessions = []
        season = organization.seasons.find(season_id)
        season.sessions.each do |session|
          sessions << session.session_name unless session.session_open.eql?('0')
        end
        sessions
      rescue
      end
    end
  end
end


