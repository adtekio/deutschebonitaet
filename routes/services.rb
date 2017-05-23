get '/add_service' do
  must_be_logged_in

  @message = session.delete(:message)

  haml :add_service
end

post '/add_service' do
  must_be_logged_in

  service = FigoSupportedService.where(:bank_code => params[:servicecode]).first
  if service.nil?
    session[:message] = "Unknown Service: #{params[:servicecode]}"
    redirect "/add_service"
  end

  user = User.find(session[:user_id])

  account = user.accounts.where(:iban => service.bank_code).first ||
    Account.create(:user           => user,
                   :iban           => service.bank_code,
                   :name           => user.name,
                   :owner          => user.name,
                   :currency       => 'EUR',
                   :bank           => Bank.for_service(service))

  if params[:creds] == "upload_instead"
    redirect "/add_transactions/#{account.id}"
  else
    account.figo_credentials = params[:creds]

    begin
      task = account.add_account_to_figo
    rescue Figo::Error => e
      session[:message] =
        "Error Adding Service #{service.bank_code}: #{e.message}"
      redirect "/add_service"
    end

    session[:message] = task.task_token
    redirect '/accounts'
  end
end

post '/service/details' do
  must_be_logged_in

  return_json do
    { :form => haml(:"_figo_bank_form", :layout => false,
                    :locals => {
                      :bank => FigoSupportedService.
                                where(:bank_code => params[:servicecode]).
                                first,
                      :iban => nil
                    })
    }
  end
end
