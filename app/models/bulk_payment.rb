require 'ajax_scaffold'

class BulkPayment < Payment
set_table_name 'payments'

@scaffold_columns = [ 
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => "date", :label => 'Fecha', :sort_sql => 'payments.date'}),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'amount', :label => 'Cantidad', :sort_sql => 'payments.amount' }),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'user_id', :label => 'Pagado a',
            :sort_sql => 'payments.user_id' }),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'ordered_by', :label => 'Pagado por',
            :sort_sql => 'payments.ordered_by' }),
  AjaxScaffold::ScaffoldColumn.new(self, 
          { :name => 'concept', :label => 'Concepto',:sort_sql => 'payments.concept' })
    ]

end
