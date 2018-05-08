class AddYearToResult < ActiveRecord::Migration[5.1]
  def change
    add_column :results, :year, :string
  end
end
