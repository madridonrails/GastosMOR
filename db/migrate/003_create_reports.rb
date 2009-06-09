class CreateReports < ActiveRecord::Migration 
  def self.up
    create_table :reports do |t|
      t.column :created_at, :timestamp
    end

  end

  def self.down
    drop_table :reports
  end
end
