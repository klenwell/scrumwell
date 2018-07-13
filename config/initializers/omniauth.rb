# https://github.com/zquestz/omniauth-google-oauth2
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           Rails.application.credentials.google_client_id,
           Rails.application.credentials.google_client_secret
end

# Catch failure errors in dev (e.g. user cancels authorization on Google page.)
# http://stackoverflow.com/a/11028187/1093087
OmniAuth.config.on_failure = Proc.new { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
