class AddOtherCommentsToResult < ActiveRecord::Migration[5.1]
  def change
    add_column :results, :other_comments, :text
    add_column :results, :latest_report_date, :datetime
    add_column :results, :latest_report, :string
    add_column :results, :third_recent_report, :string
  end
end
