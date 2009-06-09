require 'ajax_scaffold'

class Expense < ActiveRecord::Base


  belongs_to :project  
  belongs_to :user
  belongs_to :reviser, :class_name => 'User', :foreign_key => 'revised_by'
  belongs_to :expense_type
  
  add_for_sorting_to :description

@scaffold_columns = [ 
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => "status", :label => '',
          :sort_sql => 'expenses.status'}),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'date', :label => 'Fecha', :sort_sql => 'expenses.date' }),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'description', :label => 'Concepto',:sort_sql => 'expenses.description' }),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => "expense_type_id", :label => 'Tipo',
          :eval => 'expense.expense_type.description',
          :sort_sql => 'expense_types.description'}),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'amount', :label => 'Importe',:sort_sql => 'expenses.amount'}),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'project_id', :label => 'Proyecto' ,
            :eval => 'expense.project.name',
            :sort_sql => 'projects.name'}), 
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'user_id', :label => 'Usuario' ,
            :eval => 'display_user(expense.user)',
            :sort_sql => 'users.first_name_for_sorting'}),                    
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'envelope', :label => 'Sobre',:sort_sql => 'expenses.envelope'}),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'payment_type', :label => 'Forma&nbsp;Pago',:sort_sql => 'expenses.payment_type',
            :eval => 'PaymentType.combo[expense.payment_type][0]'})
    ]

  validates_presence_of     :date,
                            :message => '^La fecha no puede estar vacía'

  validates_numericality_of :amount,
                            :only_integer => true,
                            :message => '^Formato del campo importe incorrecto debe introducir el importe como cantidad , o . y decimales. Incluyendo el cero'

  validates_presence_of     :description,
                            :message => '^El concepto no puede estar vacío'

  validates_presence_of     :status,
                            :message => '^Seleccione un estado de la lista'
  validates_inclusion_of    :status,
                            :in => ExpenseStatus::ALL,
                            :message => '^Estado inexistente, seleccione uno de la lista',
                            :if => :status

  validates_presence_of     :project_id,
                            :message => '^Seleccione un proyecto de la lista'
  validates_presence_of     :project, 
                            :message => '^Proyecto inexistente, seleccione uno de la lista',
                            :if => :project_id

  validates_presence_of     :expense_type_id,
                            :message => '^Seleccione un tipo de gasto de la lista'
  validates_presence_of     :expense_type,
                            :message => '^Tipo de gasto inexistente, seleccione un tipo de gasto de la lista',
                            :if => :expense_type_id

  validates_presence_of     :payment_type,
                            :message => '^Seleccione una forma de pago'
  validates_inclusion_of    :payment_type,
                            :in => PaymentType::ALL,
                            :message => '^Forma de pago inexistente, seleccione una de la lista',
                            :if => :payment_type

  validates_presence_of     :user_id,
                            :message => '^Debe seleccionar un usuario'
  validates_presence_of     :user,
                            :message => '^Usuario inexistente',
                            :if => :user_id

  validates_presence_of     :reviser,
                            :message => '^Usuario inexistente',
                            :if => :revised_by

  def validate
    if date
      errors.add(:date, '^La fecha no es válida') unless Date.valid_date? date.year, date.mon, date.day
    end
  end
  
  def amount=(am)
    write_attribute(:amount, GastosgemUtils.format_amount(am)) 
  end
  
  def justification=(justification_field)
    self.justification_docname = base_part_of(justification_field.original_filename)
    self.justification_doctype = justification_field.content_type.chomp
    self.justification_doc = justification_field.read
  end
  
  def base_part_of(file_name)
    name = File.basename(file_name)
    name.gsub(/[^\w.-]/, '') # sanitize filename
  end
  
  def pending?
    self.status == ExpenseStatus::PENDING
  end
  
  def approved?
    self.status == ExpenseStatus::APPROVED
  end
  
  def rejected?
    self.status == ExpenseStatus::REJECTED
  end

  def status_translated
    if status == ExpenseStatus::PENDING
      'Pendiente'
    elsif status == ExpenseStatus::APPROVED
      'Aprobado'
    elsif status == ExpenseStatus::REJECTED
      'Rechazado'
    end
  end
  
  def self.count_pending
    count("status = '#{ExpenseStatus::PENDING}'")
  end
  
  def self.last_envelope(user)
    envelope = user.expenses.find(:first, :order => 'created_at desc').envelope rescue nil
  end

end
