class AddMultiEnterprise < ActiveRecord::Migration 
  def self.up
    create_table :countries do |t|
      t.column :name,             :string
    end
    
    create_table :enterprises do |t|
      t.column :short_name,       :string,  :null => false
      t.column :account_owner_id, :integer, :references => :users
      t.column :is_active,        :boolean, :default => false, :null => false
      t.column :is_blocked,       :boolean, :default => false, :null => false
      t.column :name,             :string,  :null => false
      t.column :address,          :string,  :limit => 1024
      t.column :city,             :string
      t.column :province,         :string
      t.column :postal_code,      :string
      t.column :country_id,       :integer
      t.column :cif,              :string,  :null => false
      t.column :theme,            :string,  :null => false
      t.column :extensions,       :integer
      t.column :logo,             :string
      t.column :created_at,       :timestamp
      t.column :updated_at,       :timestamp
    end

    add_column :users, :enterprise_id, :integer, :null => false
    add_column :expense_types, :enterprise_id, :integer, :null => false
    add_column :projects, :enterprise_id, :integer, :null => false
  end

  def self.down
    remove_column :users, :enterprise_id
    remove_column :expense_types, :enterprise_id
    remove_column :projects, :enterprise_id

    drop_table :enterprises
    drop_table :countries
  end

  
end
