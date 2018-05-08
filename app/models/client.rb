class Client < ApplicationRecord
  has_many :results

  def self.send_sms(message, mobile)
    puts "--- message: #{message}"
    client = Twilio::REST::Client.new ENV['TWILIO_SECRET'], ENV['TWILIO_TOKEN']
    country_code = mobile.scan(/\d/)[0,2].join.to_i
    if country_code == 61 || country_code == 64
      from = ENV['TWILIO_NUMBER_AU']
    elsif country_code == 44
      from = ENV['TWILIO_NUMBER_UK']
    else
      from = ENV['TWILIO_NUMBER_USA']
    end
    res = client.messages.create({
        from: from,
        to: mobile,
        body: message
      })
      puts ">>>>>>>> #{res} <<<<<<<"
  end

  def fetch_timezone
    country_code = self.mobile.scan(/\d/)[0,2].join.to_i
    if country_code == 61
      return 'Australia/Sydney'
    elsif country_code == 64
      return 'Pacific/Auckland'
    elsif country_code == 44
      return 'Europe/London'
    else
      return 'Eastern Time (US & Canada)'
    end
  end

  def get_all_month_average_income
    a = self.results.last(12).pluck(:revenue_last_month)
    if a.blank?
      return ""
    else
      return a.map(&:to_i).inject(&:+).to_i / a.size
    end
  end

  def get_run_rate
    a = self.results.last(3).pluck(:revenue_last_month)
    if a.blank?
      return ""
    else
      return a.map(&:to_i).inject(&:+).to_i / a.size
    end
  end
end
