require "omniauth-google-oauth2"
# OmniAuth.config.full_host = "http://app.opustime.com/"
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, CONFIG[:CALENDAR_CLIENT_ID], CONFIG[:CALENDAR_SECRET_ID], {:provider_ignores_state => true}
   { access_type: 'offline',
     approval_prompt: 'force',
     scope: 'email, profile, calendar',
     # scope: 'https://www.googleapis.com/auth/userinfo.email , https://www.googleapis.com/auth/calendar',
     redirect_uri:'http://localhost:3000/auth/google_oauth2/callback'
   }

  provider :facebook, CONFIG[:FB_KEY], CONFIG[:FB_SECRET],
  scope: ' email,user_birthday,user_location,user_hometown , user_about_me', display: 'popup'
end


 