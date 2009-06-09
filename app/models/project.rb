require 'ajax_scaffold'

class Project < ActiveRecord::Base

  has_many :expenses
  belongs_to :enterprise
  belongs_to :supervisor, :class_name => 'User', :foreign_key => 'supervisor_id'
  
  add_for_sorting_to :name, :description

  before_destroy :check_destroy
    
  @scaffold_columns = [ 
    AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => "name", :label => 'Nombre',
          :sort_sql => 'projects.name_for_sorting'}),
    AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => "description", :label => 'Descripci&oacute;n',
          :sort_sql => 'projects.description_for_sorting'}),
    AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => "supervisor_id", :label => 'Supervisor',
          :eval => 'display_user(project.supervisor)',
          :sort_sql => 'projects.supervisor_id'})               
  ]
  
  validates_presence_of     :name,
                            :message => '^El nombre no puede quedar vac&iacute;o'
  validates_uniqueness_of   :name, :case_sensitive => false, :scope => :enterprise_id,
                            :message => '^El nombre del proyecto ya existe, elija otro por favor'
                            
  validates_presence_of     :enterprise_id,
                            :message => '^Debe seleccionar una empresa'
  validates_presence_of     :enterprise,
                            :message => '^Empresa inexistente',
                            :if => :enterprise_id

  validates_presence_of     :supervisor_id,
                            :message => '^Debe seleccionar un supervisor'
  validates_presence_of     :supervisor,
                            :message => '^Supervisor inexistente, seleccione uno de la lista',
                            :if => :supervisor_id

  def validate
    if supervisor
      errors.add(:supervisor, '^Supervisor inexistente, seleccione uno de la lista') unless supervisor.is_supervisor?
    end
  end
  
  def self.create_default(user)
    Project.new :name => 'General', :description => 'Proyecto general', :supervisor => user
  end
  
  #No se pueden borrar un proyecto si hay algun gasto asociado
  def check_destroy              
    raise ActiveRecord::RecordNotSaved.new("No se puede borrar '#{self.name}'. Existen #{expenses.length} gastos asociados.") if expenses.length > 0                      
  end
  
end
