# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Meducation::Application.initialize!

OmniAuth.config.on_failure = OmniauthCallbackController.action(:oauth_failure)
# config.force_ssl = true
