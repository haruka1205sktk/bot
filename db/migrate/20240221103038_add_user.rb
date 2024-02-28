class AddUser < ActiveRecord::Migration[6.1]
  def change
    add_column :languages, :user, :string
    add_column :languages, :userid, :integer
  end
end
