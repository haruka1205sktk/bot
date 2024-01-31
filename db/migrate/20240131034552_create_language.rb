class CreateLanguage < ActiveRecord::Migration[6.1]
  def change
    create_table :languages do |t|
      t.string :language
    end
  end
end
