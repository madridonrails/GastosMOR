require 'ajax_scaffold'

class ExpenseType < ActiveRecord::Base

  before_destroy :check_destroy
  
  belongs_to :enterprise
  has_many :expenses
  acts_as_tree
  
  @scaffold_columns = [ 
    AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => "description", :label => 'Nombre',
            :sort_sql => 'expense_types.description'}),
    AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => "parent_id", :label => 'Tipo padre',
            :eval => 'expense_type.parent.description',
            :sort_sql => 'expense_types.parent_id'}),
  ]

  validates_presence_of     :description,
                            :message => '^La descripción no puede estar vacía.'
  validates_uniqueness_of   :description, :case_sensitive => false, :scope => :enterprise_id,
                            :message => '^Este tipo de gasto ya existe, elija otro por favor.'                            

  validates_presence_of     :enterprise_id,
                            :message => '^Debe seleccionar una empresa'
  validates_presence_of     :enterprise,
                            :message => '^Empresa inexistente',
                            :if => :enterprise_id

  validates_presence_of     :parent,
                            :message => '^Tipo padre inexistente, seleccione uno de la lista',
                            :if => :parent_id

  def self.create_default enterprise
    general = ExpenseType.new(:description => 'General', :enterprise => enterprise)
    transport = ExpenseType.new(:description => 'Transporte', :enterprise => enterprise)
      transport.children << ExpenseType.new(:description => 'Taxi', :enterprise => enterprise)
      transport.children << ExpenseType.new(:description => 'Kilómetros', :enterprise => enterprise)
      transport.children << ExpenseType.new(:description => 'Tren', :enterprise => enterprise)
      transport.children << ExpenseType.new(:description => 'Avión', :enterprise => enterprise)
      transport.children << ExpenseType.new(:description => 'Parking', :enterprise => enterprise)
    maintenance = ExpenseType.new(:description => 'Manutención', :enterprise => enterprise)
      maintenance.children << ExpenseType.new(:description => 'Hotel', :enterprise => enterprise)
      maintenance.children << ExpenseType.new(:description => 'Comidas clientes', :enterprise => enterprise)
    purchases = ExpenseType.new(:description => 'Pequeñas compras', :enterprise => enterprise)
      purchases.children << ExpenseType.new(:description => 'Material de oficina', :enterprise => enterprise)
      purchases.children << ExpenseType.new(:description => 'Otros', :enterprise => enterprise)
    [general, transport, maintenance, purchases]
  end  

  #No se pueden borrar tipos de gastos si hay algun gasto asociado
  def check_destroy            
    raise ActiveRecord::RecordNotSaved.new("No se puede borrar '#{self.description}'. Existen #{expenses.length} gastos asociados") if expenses.length > 0
    raise ActiveRecord::RecordNotSaved.new("No se puede borrar '#{self.description}'. Es padre de otros #{children.length} tipos de gastos") if children.length > 0                 
  end
end

