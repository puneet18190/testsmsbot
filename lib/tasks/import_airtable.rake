require 'airtable'
task import_airtable: :environment do
	@client = Airtable::Client.new('keyzr5WzBs1ucj5P6')
	@table = @client.table('tblWlWBcJe3KFyyQY', "Clients")
	@results = @client.table('tblWlWBcJe3KFyyQY', "Results")	
	@records = @table.records
	@records.each do |c|
		check_client = Client.where(clientid: c.id)
		if check_client.blank?
			client = Client.new
		else
			client = check_client.first
		end
		client.clientid = c.try(:id)
		client.mobile = c.try(:mobile)
		client.first_name = c.try(:first_name)
		client.last_name = c.try(:last_name)
		client.email = c.try(:email)
		client.avg_revenue = c.try(:all_time_average_revenue)
		client.latest_report_date = c.try(:latest_report_date)
		client.run_rate = c.try(:run_rate)
		client.all_month_average_revenue = c.try(:all_month_average_revenue)
		client.time_zone = c.try(:time_zone)
		client.latest_month_revenue = c.try(:latest_month_revenue)
		client.third_latest_report_date = c.try(:third_latest_report_date)
		client.baseline_12_month_income = c.try(:baseline_12_month_income)
		client.ontraport_id = c.try(:ontraport_id)
		client.all_month_average_income = c["12_month_average_income"]
		client.save

		if c["results"].present?
			c.results.each do |c_r|
				check_result = Result.where(resultid: c_r)
				if check_result.blank?
					result = client.results.new
				else
					result = check_result.first 	
				end
				r = @results.find(c_r)
				if r.present?
					result.resultid = r.id 
					result.help = r.try(:help) 
					result.revenue_last_month = r.try(:revenue_last_month )
					result.mobile_number = r.try(:mobile_number)
					result.income_goal = r.try(:income_goal_this_month )
					result.date = r.try(:date)
					result.month = r.try(:month)
					result.other_comments = r.try(:other_comments)
					result.latest_report_date = r.try(:latest_report_date)
					result.latest_report = r.try(:latest_report)
					result.third_recent_report = r.try(:third_recent_report)
					result.year = r.try(:year)
					result.save
				end
			end
		end
	end
end