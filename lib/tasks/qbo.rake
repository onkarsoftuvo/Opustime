namespace :intuit do
  task :auto_refresh_qbo_credentials => :environment do
    QuickBookInfo.all.each do |record|

      if record.reconnect_token_at <= Time.now.utc
        access_token = OAuth::AccessToken.new($qb_oauth_consumer, record.token, record.secret)
        service = Quickbooks::Service::AccessToken.new
        service.access_token = access_token
        service.company_id = record.realm_id
        result = service.renew

        # result is an AccessTokenResponse, which has fields token and secret
        # update your local record with these new params
        record.token = result.token
        record.secret = result.secret
        record.token_expires_at = 6.months.from_now.utc
        record.reconnect_token_at = 5.months.from_now.utc
        record.save!
        p "=====company_id=#{record.company.id} Quickbooks credentials has been auto_renewed"
      else
        p 'Quickbooks credentials are not expire yet'
      end

    end
  end

  # update qbo all income and expense accounts
  task :update_income_and_expense_accounts=>:environment do
    QboAccount.create(:qbo_id=>1,:qbo_account_name=>'test')
  end
end

