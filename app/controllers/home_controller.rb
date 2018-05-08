class HomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: ['receive_sms', 'test']
  def index
    @client = Airtable::Client.new(ENV['AIRTABLE_API_KEY'])
    @table = @client.table(ENV['AIRTABLE_APP_KEY'], "Clients")
    @records = @table.records
  end

  def results
    @client = Airtable::Client.new(ENV['AIRTABLE_API_KEY'])
    @table = @client.table(ENV['AIRTABLE_APP_KEY'], "Clients")
    client = @table.find(params[:client])
    results = client.results
    @data = []
    @results = @client.table(ENV['AIRTABLE_APP_KEY'], "Results")
    results.each do |r|
      @data << @results.find(r)
    end
  end

  def send_sms
    @client = Client.all
    @client.each do |c|
      begin
        if c.results.blank?
          message = "Hey #{c.first_name}, I'm #BeltBot, the Black Belt SMS bot. I'm programmed to help you make your monthly income go up, and get you help when you need it. First, let's get a baseline. What was your total revenue over the past 12 months?"
          Client.send_sms( message, c.mobile)
        else
          month =  Date::MONTHNAMES[c.results.last.month.to_i+1]
          Client.send_sms("Hey, #{c.first_name}, it’s your friendly Black Belt #BeltBot here, what’s your income goal for #{month}?", c.mobile)
          c.update(sms_status: 1)
        end
      rescue Exception => e
        puts ">>>>>>>>>>Exception In Send SMS Action <<<<<<<<<<<<<<"
        puts ">>> #{e.message} <<<"
        Bugsnag.notify(e)
      end
    end
  end

  def receive_sms
    begin
      client = Client.where(mobile: params['From'].gsub('+','')).first
      if client
        case client.sms_status
        when 0
          message = params['Body'].gsub('$','').gsub(',','').gsub('k','000').gsub('K','000')
          if valid_message(message)
            from = params['From'].gsub('+','')
            avg = message
            puts " ???????? #{avg} ?????????"
            avg = avg.blank? ? "" : (avg.to_f/12).round
            puts " ???????? #{avg} ?????????"
            Client.send_sms("Ok, so that's about #{avg} per month. Perfect. And, #{client.first_name} what’s your income goal for #{DateTime.now.strftime('%B')}?", client.mobile)
            client.update(sms_status: 1)
            client.update(baseline_12_month_income: message)
            sync_airtable('update_client', client.clientid, {"Baseline 12 Month Income"=> message.to_i, "Baseline 12 Month Average Income"=>avg.to_i})
          else
            Client.send_sms("That's not an input I understand. Please respond in dollars - e.g. $50k", client.mobile)
          end
        when 1
          message = params['Body'].gsub('$','').gsub(',','').gsub('k','000').gsub('K','000')
          if valid_message(message)
            from = params['From'].gsub('+','')
            if client.results.blank?
              prev_month =  (DateTime.now-1.month).strftime('%m').to_i
              month =  DateTime.now.strftime('%m').to_i
            else
              prev_month =  client.results.last.month.to_i
              month =  client.results.last.month.to_i+1
            end
            Client.send_sms("Roger that, #{params['Body']} for #{Date::MONTHNAMES[month]}. And what did you bank in #{Date::MONTHNAMES[prev_month]}?", client.mobile)
            client.update(sms_status: 2)
            client.results.create(income_goal: message, mobile_number: from, month: month)
            sync_airtable('create', client.clientid, {income_goal_this_month: message.to_i, mobile_number: from, month: month.to_i, date: Time.zone.now.strftime('%Y-%m-%d'), year: Time.zone.now.strftime('%Y').to_i})
          else
            Client.send_sms("That's not an input I understand. Please respond in dollars - e.g. $50k", client.mobile)
          end
        when 2
          message = params['Body'].gsub('$','').gsub(',','').gsub('k','000').gsub('K','000')
          if valid_message(message)
            last_revenue = client.results.all[-2].try(:revenue_last_month)
            if last_revenue.present? 
              diff = message.to_f - last_revenue.to_f
              puts ">>>>>>>>> Diff #{diff}"
              if diff > 3000
                Client.send_sms('Cool! Looks like things are headed in the right direction. Anything you need help with?', client.mobile)
              elsif diff.to_i.between?(-3000, 3000)
                Client.send_sms(' Hmmm, those numbers seem a bit flat, what do you need most right now ?', client.mobile)
              else
                Client.send_sms(' Hmmm, looks like those numbers aren’t going up... What do you need most right now?', client.mobile)
              end
            else
              Client.send_sms("Gotcha. Thanks for the replies. I'm in touch with Taki and the Sherpas. Need anything right now?", client.mobile)
            end
            client.update(sms_status: 3)
            client.results.last.update(revenue_last_month: message)
            sync_airtable('update', client.clientid, {"Revenue Last Month" => message.to_i})
            all_month_average_income = client.get_all_month_average_income
            run_rate = client.get_run_rate
            sync_airtable('update_client_run_rate', client.clientid, {"12 Month Average Income" => all_month_average_income.to_i, "Run Rate" => run_rate.to_i})
            send_ontraport({id: client.ontraport_id, all_month_average_income: all_month_average_income, run_rate: run_rate}) if client.ontraport_id.present?
          else
            Client.send_sms("That's not an input I understand. Please respond in dollars - e.g. $50k", client.mobile)
          end
        when 3
          message = params['Body'].to_s
          client.update(sms_status: 4)
          client.results.last.update(help: message)
          sync_airtable('update', client.clientid, {"Help" => message})
          Client.send_sms("Got it, #{client.first_name}. I'll pass your updates onto the team now. Thanks for messaging #BeltBot", client.mobile)
          send_intercom(message, client.email)
        # when 4
        #   message = params['Body'].to_s
        #   client.update(sms_status: 5)
        #   Client.send_sms("Got it, #{client.first_name}. I'll pass this onto the team today.", client.mobile)
        end
        render json: {status: true}
      end
    rescue => exception
      Bugsnag.notify(exception)
    end
  end

  def sync_airtable(action, client, params)
    begin
      @client = Airtable::Client.new(ENV['AIRTABLE_API_KEY'])
      @client_table = @client.table(ENV['AIRTABLE_APP_KEY'], "Clients")
      @result_table = @client.table(ENV['AIRTABLE_APP_KEY'], "Results")
      if action == 'create'
        record = Airtable::Record.new("Income Goal This Month"=>params[:income_goal_this_month], "Mobile Number"=>params[:mobile_number], "Client Record"=>[client], "Month"=> params[:month], "Year"=> params[:year], "Date"=> params[:date])
        res = @result_table.create(record)
        puts ">>>>>>>>>>>>> Result Table created record <<<<<<<<<<"
        puts res
      elsif action=='update_client'
        record = @client_table.find(client)
        #record[params.first[0]] = params.first[1]
        #update_record=Airtable::Record.new("Results"=> record[:results], "Mobile"=>record[:mobile],"Last Name"=>record[:last_name],"First Name"=>record[:first_name],"Email"=> record[:email], :id => record[:id],"Baseline 12 Month Income"=>params['Baseline 12 Month Income'],"Baseline 12 Month Average"=>params['Baseline 12 Month Average'])
        #res = @client_table.update(update_record)
        res = @client_table.update_record_fields(client, params)
        puts '>>>>>>>>>>> Client Table updated record <<<<<<<<<<<<'
        puts res
      elsif action=='update_client_run_rate'
        record = @client_table.find(client)
        res = @client_table.update_record_fields(client, params)
        puts '>>>>>>>>>>> Client Run Rate & Avg Revenue Table updated record <<<<<<<<<<<<'
        puts res  
      else
        client = @client_table.find(client)
        if client
          last_result = client.results.last
          if last_result
            record = @result_table.find(last_result)
            update_record = Airtable::Record.new(:id => record[:id],"Help"=>record[:help],"Revenue Last Month"=>record[:revenue_last_month], "Mobile Number"=>record[:mobile_number], "Client Record"=>record[:client_record], "Income Goal This Month" => record[:income_goal_this_month], "Month"=>record[:month], "Year"=>record[:year], "Date"=>record[:date])
            update_record[params.first[0]] = params.first[1]
            res = @result_table.update(update_record)
            puts ">>>>>>>>>>>>> Result Table updated record <<<<<<<<<<"
            puts res
          end
        end
      end
    rescue Exception => e
      puts ">>>>>>>>>>Exception In Airtable <<<<<<<<<"
      puts e.message
      Bugsnag.notify(e)
    end
  end

  def send_intercom(message, email)
    begin
      intercom = Intercom::Client.new(token: ENV['INTERCOM_API_KEY'])
      res = intercom.messages.create({
        from: {
          type: 'user',
          email: email #ENV['INTERCOM_EMAIL']
        },
        body: "Message from SMS Bot: "+message
      })
      puts res
    rescue Exception => e
      puts ">>>>>>>> Exception In Intercom <<<<<<<<"
      puts e.message
      Bugsnag.notify(e)
    end
  end

  def send_ontraport(params)
    puts ">>> Ontraport params: #{params}"
    begin
      # Ontraport.configure do |config|
      #   config.api_id = '2_429_9mcOxi1n5'
      #   config.api_key = 'tM5kwyvGJJktnmL'
      # end
      # Ontraport.save_or_update :contact, params
      client = OntraportApi::Client.new('2_429_9mcOxi1n5','tM5kwyvGJJktnmL')
      client.update_contact(params[:id], {f1896: params[:all_month_average_income], f1897: params[:run_rate]})
      puts "======= Ontraport Api runs successfully. ======="
    rescue Exception => e
      puts ">>>>>>>> Exception In Ontraport <<<<<<<<"
      puts e.message
      Bugsnag.notify(e)
    end
  end

  def test
    begin
      params[:request_type]=request.env['REQUEST_METHOD']
      Datum.create(name: params.to_json)
      if params["data"].present?
        firstname = params["data"]["firstname"]
        lastname = params["data"]["lastname"]
        email = params["data"]["email"]
        mobile = params["data"]["sms_number"]
        timezone = params["data"]["f1899"].present? ? params["data"]["f1899"] : params["data"]["timezone"]
        ontraport_id = params["data"]["id"]
        
        @client = Airtable::Client.new(ENV['AIRTABLE_API_KEY'])
        @client_table = @client.table(ENV['AIRTABLE_APP_KEY'], "Clients")
        client = Airtable::Record.new("Mobile" => mobile, "First Name"=>firstname, "Last Name"=>lastname, "Email"=>email, "Time Zone"=>timezone, "Ontraport ID"=>ontraport_id)
        res = @client_table.create(client)
        Client.create(first_name: firstname, last_name: lastname, email: email, mobile: mobile, time_zone: timezone, ontraport_id: ontraport_id, clientid: res.id)
      end
      render json: {status: true}
    rescue Exception => e
      render json: {status: false}
      Bugsnag.notify(e)
    end
  end

  def valid_message(message)
    return message.scan(/\d+/).first.present?
  end
end

# <Twilio.Api.V2010.MessageInstance account_sid: AC8e9fb23fef4a3ad193d471aeac44aa64 sid: SMb6d5e515a389491b8de4a4cc03c49eef>
# <Twilio.Api.V2010.MessageInstance account_sid: AC8e9fb23fef4a3ad193d471aeac44aa64 sid: SMf5d969197ad94d0cb86ba1034e6350f4>

 # {
 #  "ToCountry"=>"AU",
 #   "ToState"=>"",
 #   "SmsMessageSid"=>"SM00775159d6cc22725538926b89717a4e",
 #   "NumMedia"=>"0",
 #   "ToCity"=>"",
 #   "FromZip"=>"",
 #   "SmsSid"=>"SM00775159d6cc22725538926b89717a4e",
 #   "FromState"=>"",
 #   "SmsStatus"=>"received",
 #   "FromCity"=>"",
 #   "Body"=>"20",
 #   "FromCountry"=>"AU",
 #   "To"=>"+61488843286",
 #   "ToZip"=>"",
 #   "NumSegments"=>"1",
 #   "MessageSid"=>"SM00775159d6cc22725538926b89717a4e",
 #   "AccountSid"=>"AC8e9fb23fef4a3ad193d471aeac44aa64",
 #   "From"=>"+61420352343",
 #   "ApiVersion"=>"2010-04-01",
 #   "controller"=>"home",
 #   "action"=>"receive_sms"}

 #curl -H "Content-Type: application/json" -X POST -d '{"From":"","Body":""}' http://0.0.0.0:3000/receive_sms
