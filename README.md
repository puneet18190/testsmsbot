# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
# tmsmschatbot
SMS Chatbot
keymrHXseo9QzWnF4
appfHaDk94Fr93kEv

a="keymrHXseo9QzWnF4"
b="appfHaDk94Fr93kEv"
@client = Airtable::Client.new(a)
@client_table = @client.table(b, "Clients")
params={}
params={"Baseline 12 Month Income" => 100, "Baseline 12 Month Average Income" =>200}
res = @client_table.update_record_fields("recGuEm2WHrvSY5Ev", params)

res = @client_table.update_record_fields("recEu6mySV0t6BOqg", params)

client=@client_table.records.last
record = @client_table.find("recEu6mySV0t6BOqg")

update_record=Airtable::Record.new("Results"=> record[:results], "Mobile"=>record[:mobile],"Last Name"=>record[:last_name],"First Name"=>record[:first_name],"Email"=> record[:email], :id => record[:id],"Baseline 12 Month Income"=>params['Baseline 12 Month Income'],"Baseline 12 Month Average"=>params['Baseline 12 Month Average'])

res = @client_table.update(update_record)

Result.all.destroy_all
Client.all.destroy_all

heroku run rake import_airtable
heroku run rake send_sms_now

client = OntraportApi::Client.new('2_429_9mcOxi1n5','tM5kwyvGJJktnmL')
      client.update_contact(params[:id], {f1896: params[:all_month_average_income], f1897: params[:run_rate]})