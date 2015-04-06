Geocoder.configure(
    # geocoding options
    timeout:       40  ,  #      # geocoding service timeout (secs)
    ip_lookup:     :maxmind_local, # http://dev.maxmind.com/geoip/legacy/geolite/
    maxmind_local: {file: Rails.root.join("lib/geolitedb/GeoLiteCity.dat")}
    # :lookup       => :google,     # name of geocoding service (symbol)
    # :language     => :en,         # ISO-639 language code
    # :use_https    => false,       # use HTTPS for lookup requests? (if supported)
    # :http_proxy   => nil,         # HTTP proxy server (user:pass@host:port)
    # :https_proxy  => nil,         # HTTPS proxy server (user:pass@host:port)
    # :api_key      => nil,         # API key for geocoding service
    # :cache        => nil,         # cache object (must respond to #[], #[]=, and #keys)
    # :cache_prefix => "geocoder:", # prefix (string) to use for all cache keys

    # exceptions that should not be rescued by default
    # (if you want to implement custom error handling);
    # supports SocketError and TimeoutError
    # :always_raise => [],

    # calculation options
    # :units     => :mi,       # :km for kilometers or :mi for miles
    # :distances => :linear    # :spherical or :linear
    #:maxmind => {:service => :country}
)
# possible ip_lookup are
# :dstk, :esri, :google, :google_premier, :yahoo, :bing, :geocoder_ca, :geocoder_us, :yandex, :nominatim, :mapquest, :ovi, :here, :baidu, :cloudmade, :geocodio, :smarty_streets, :test, :freegeoip, :maxmind, :maxmind_local, :baidu_ip)