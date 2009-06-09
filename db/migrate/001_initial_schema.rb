class InitialSchema < ActiveRecord::Migration 
  def self.up
    create_table :users do |t|
      t.column :is_supervisor,              :boolean, :default => false, :null => false
      t.column :is_administrator,           :boolean, :default => false, :null => false
      t.column :first_name,                 :string
      t.column :first_name_for_sorting,     :string
      t.column :last_name,                  :string
      t.column :last_name_for_sorting,      :string      
      t.column :is_payer,                   :boolean, :default => false
      t.column :supervisor_id,              :integer, :references => :users
      t.column :email,                      :string, :default => ""
      t.column :crypted_password,           :string, :limit => 40
      t.column :salt,                       :string, :limit => 40
      t.column :created_at,                 :datetime
      t.column :updated_at,                 :datetime
      t.column :remember_token,             :string
      t.column :remember_token_expires_at,  :datetime
      t.column :activation_code,            :string, :limit => 40
      t.column :activated_at,               :datetime
      t.column :is_gestor,                  :boolean, :default => false
      t.column :is_blocked,                 :boolean, :default => false
    end

    create_table :projects do |t|
      t.column :name,                       :string, :default => "", :null => false
      t.column :name_for_sorting,           :string
      t.column :description,                :string
      t.column :description_for_sorting,    :string
      t.column :supervisor_id,              :integer, :references => :users
    end
    
    create_table :expense_types do |t|
      t.column :description,                :string # there's no need to order by field lexicographically
      t.column :parent_id,                  :integer, :references => :expense_types
    end
    
    create_table :expenses do |t|
      t.column :user_id,                    :integer
      t.column :project_id,                 :integer
      t.column :description,                :string, :default => "", :null => false
      t.column :description_for_sorting,    :string
      t.column :date,                       :date
      t.column :amount,                     :integer
      t.column :justification_doc,          :binary
      t.column :justification_docname,      :string
      t.column :justification_doctype,      :string
      t.column :status,                     :string
      t.column :revised_by,                 :integer, :references => :users # may or may not be a supervisor at the time of reading
      t.column :revised_at,                 :date
      t.column :revision_note,              :string
      t.column :expense_type_id,            :integer
      t.column :comments,                   :string
      t.column :envelope,                   :string
      t.column :created_at,                 :date
      t.column :updated_at,                 :date
      t.column :payment_type,               :integer, :default => 1, :null => false
    end
    add_index :expenses, :status
    
    create_table :payments do |t|
      t.column :user_id,                    :integer
      t.column :date,                       :date
      t.column :amount,                     :integer, :default => 0, :null => false
      t.column :ordered_by,                 :integer, :references => :users # may or may not be a supervisor at the time of reading
      t.column :concept,                    :string
      t.column :concept_for_sorting,        :string
      t.column :description,                :string 
    end
  end
  
  def self.down
    drop_table :payments    
    drop_table :expenses
    drop_table :expense_types
    drop_table :projects
    drop_table :users
  end
end
