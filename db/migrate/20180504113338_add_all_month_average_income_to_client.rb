class AddAllMonthAverageIncomeToClient < ActiveRecord::Migration[5.1]
  def change
    add_column :clients, :all_month_average_income, :string
  end
end
