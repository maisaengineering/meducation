#if Rails.env.production?
#  Braintree::Configuration.environment = :production
#  Braintree::Configuration.merchant_id = "yqgc5nynxdxht4xg"
#  Braintree::Configuration.public_key = "g8fh6dmdt9vnhkk4"
#  Braintree::Configuration.private_key = "b8dbb2b195f6aac8cb808c2a3638aec5"
#else
  Braintree::Configuration.environment = :sandbox
  Braintree::Configuration.merchant_id = "qyf39jcdmjx5gntz"
  Braintree::Configuration.public_key = "gth2q43tpj57cfxx"
  Braintree::Configuration.private_key = "9e3d675f6e491b4d225187212027f490"
#end
