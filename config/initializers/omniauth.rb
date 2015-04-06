OmniAuth.config.logger = Rails.logger
Rails.application.config.middleware.use OmniAuth::Builder do
  if Rails.env.development?
    provider :facebook, '167364123452905', '46a09123a188afe02f422f280ca289bc', {:scope =>"photo_upload", client_options: {ssl: {ca_path: "/etc/ssl/certs"}}}#, :display => 'popup'
  else
    provider :facebook, '648787091808578', 'f7c0865816210bf1c582c3c14ad859fd', {:scope =>"photo_upload", client_options: {ssl: {ca_path: "/etc/ssl/certs"}}}#, :display => 'popup'
  end
end



