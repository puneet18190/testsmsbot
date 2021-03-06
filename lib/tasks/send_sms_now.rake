require 'twilio-ruby'
task send_sms_now: :environment do
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

      #if ( t1.strftime('%D') == t2.strftime('%D') && t2.strftime('%T') < t1.strftime('%T'))
    
        if c.results.blank?
          message = "Hey #{c.first_name}, I'm #BeltBot, the Black Belt SMS bot. I'm programmed to help you make your monthly income go up, and get you help when you need it. First, let's get a baseline. What was your income over the past 12 months?"
          Client.send_sms( message, c.mobile)
        else
          month =  Date::MONTHNAMES[c.results.last.month.to_i+1]
          Client.send_sms("Hey, #{c.first_name}, it’s your friendly Black Belt #BeltBot here, what’s your income goal for #{month}?", c.mobile)
          c.update(sms_status: 1)
        end
      #end  
    rescue Exception => e
      puts ">>>>>>>>>>Exception In Send SMS Now <<<<<<<<<<<<<<"
      puts ">>> #{e.message} <<<"
      Bugsnag.notify(e)
    end
  end
end