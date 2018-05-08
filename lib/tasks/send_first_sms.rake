require 'twilio-ruby'
task send_first_sms: :environment do
  @client = Client.all
  @client.each do |c|
    begin
      message = "#{c.first_name}, it's Taki. Just wanted to let you know that our new #BeltBot will sms you soon. I built it to help us make your revenue go up this year. Look out for the message, and reply to it as soon as you can, ok?"
      Client.send_sms(message, c.mobile)
    rescue Exception => e
      puts ">>>>>>>>>>Exception In Send First SMS <<<<<<<<<<<<<<"
      puts ">>> #{e.message} <<<"
      Bugsnag.notify(e)
    end
  end
end