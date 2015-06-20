class CreateSoundings < ActiveRecord::Migration
	def change
		create_table :soundings do |t|
			t.string :model
			t.datetime :run_at
			t.datetime :valid_at
			t.integer :index
			t.string :params
			t.integer :hour

			t.timestamps :null => false
		end
	end
end