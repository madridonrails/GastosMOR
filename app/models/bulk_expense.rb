require 'ajax_scaffold'

class BulkExpense < Expense
  set_table_name "expenses"
  
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
          :eval => 'bulk_expense.expense_type.description',
          :sort_sql => 'expense_types.description'}),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'amount', :label => 'Importe',:sort_sql => 'expenses.amount'}),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'project_id', :label => 'Proyecto' ,
            :eval => 'bulk_expense.project.name',
            :sort_sql => 'projects.name'}),          
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'envelope', :label => 'Sobre',:sort_sql => 'expenses.envelope'}),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'payment_type', :label => 'Forma&nbsp;Pago',:sort_sql => 'expenses.payment_type',
          :eval => 'PaymentType.combo[bulk_expense.payment_type][0]'}),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'created_at', :label => 'F. Alta', :sort_sql => 'expenses.created_at' })                   
    ]
    

end
