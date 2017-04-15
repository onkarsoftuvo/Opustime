$qb_key = QBO_CONFIG['qbk_customer_key']
$qb_secret = QBO_CONFIG['qbk_customer_secret']

$qb_oauth_consumer = OAuth::Consumer.new($qb_key, $qb_secret, {
                                                    :site => "https://oauth.intuit.com",
                                                    :request_token_path => "/oauth/v1/get_request_token",
                                                    :authorize_url => "https://appcenter.intuit.com/Connect/Begin",
                                                    :access_token_path => "/oauth/v1/get_access_token"
                                                })
QboApi.production = true if Rails.env.production?
Quickbooks.sandbox_mode = true if Rails.env.development?
QboApi.log = true
QboApi.logger = Rails.logger
# QboApi.request_id = true
