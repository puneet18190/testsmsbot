class AddLatestReportDateToClient < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :latest_report_date, :datetime
    add_column :clients, :run_rate, :string
    add_column :clients, :all_month_average_revenue, :string
    add_column :clients, :time_zone, :string
    add_column :clients, :latest_month_revenue, :string
    add_column :clients, :third_latest_report_date, :datetime
    add_column :clients, :baseline_12_month_income, :string
    add_column :clients, :baseline_12_month_revenue, :string
  end
end
