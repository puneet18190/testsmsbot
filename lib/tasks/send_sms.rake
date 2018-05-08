require 'twilio-ruby'
task send_sms: :environment do
  @client = Client.all
  @client.each do |c|
    begin
      timezone = c.time_zone
      Time.zone = timezone.present? ? timezone : c.fetch_timezone #'UTC'
      year = Time.zone.now.strftime('%Y')
      month = Time.zone.now.strftime('%m')
      date = ENV['SEND_SMS_DATE']
      hour = ENV['SEND_SMS_HOUR']
      min = ENV['SEND_SMS_MINUTE']

      t1=Time.zone.now
      t2=Time.zone.local(year,month,date,hour,min)

      if c.sent_at.blank?
        if ( t1.strftime('%D') == t2.strftime('%D') && t2.strftime('%T') < t1.strftime('%T'))
        #if ( t1.strftime('%A') == t2.strftime('%A') && t1.strftime('%d').to_i <= 7 && t2.strftime('%T') < t1.strftime('%T')) #condition to send sms at every first monday
      
          if c.results.blank?
            message = "Hey #{c.first_name}, I'm #BeltBot, the Black Belt SMS bot. I'm programmed to help you make your monthly income go up, and get you help when you need it. First, let's get a baseline. What was your total revenue over the last 12 months?"
            Client.send_sms( message, c.mobile)
          else #if c.sms_status == 0 || (c.sms_status == 1 && (t1-c.updated_at.in_time_zone)/1.days > 3)
            month =  Date::MONTHNAMES[c.results.last.month.to_i+1]
            Client.send_sms("Hey, #{c.first_name}, it’s your friendly Black Belt #BeltBot here, what’s your income goal for #{month}?", c.mobile)
            c.update(sms_status: 1)
          end
          c.update(sent_at: t1)
        end
      end  
    rescue Exception => e
      puts ">>>>>>>>>>Exception In Send SMS <<<<<<<<<<<<<<"
      puts ">>> #{e.message} <<<"
    end
  end
end