require 'faster_csv'

class BulkExpensesController < ApplicationController
  include AjaxScaffold::Controller
  
  AbbrMonthnames = [nil] + %w{Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic}
  
  after_filter :clear_flashes
  before_filter :update_params_filter
  before_filter :expense_not_approved, :only =>[:update, :destroy]
  prepend_before_filter :reset_filter_params, :only =>[:list]
  
  #Comprueba que el id que viene pertenece a la empresa
  #before_filter :validate_enterprise, :only => [:edit,:update,:destroy]
  
  #Comprueba que el id pertenece al usuario logado
  before_filter :validate_owner, :only => [:edit,:update,:destroy,]

  private
  
  CSV_HEADERS = ['fecha', 'concepto', 'importe', 'sobre', 'forma pago', 'tipo', 'proyecto']
  
  #Valida que el id que llega pertenece a la empresa del usuario logado.  
  def validate_enterprise
    expense = Expense.find(params[:id],:include=>'user',:conditions=>['users.enterprise_id=?',@enterprise.id],:select=>['id']) rescue nil
    !expense.blank?
  end
  
  #Valida que el id que llega pertenece al usuario logado.  
  def validate_owner
    expense = @current_user.expenses.find(params[:id]) rescue nil
    !expense.blank?
  end
  
  public
  
  def auto_complete_for_bulk_expense_envelope
    @items=BulkExpense.find(:all,:include=>'user',
              :conditions=>['envelope like ? and users.enterprise_id=? and user_id=?',"%#{params[:bulk_expense][:envelope]}%",@enterprise.id,@current_user.id])    
    render :inline => '<%= auto_complete_result(@items, "envelope") %>'
  end

  def auto_complete_for_bulk_expense_description
    @items=BulkExpense.find(:all,:include=>'user',
        :conditions=>['description like ? and users.enterprise_id=? and user_id=?',"%#{params[:bulk_expense][:description]}%",@enterprise.id,@current_user.id])    
    render :inline => '<%= auto_complete_result(@items, "description") %>'
  end

  def auto_complete_for_filter_expense_description
    @items=BulkExpense.find(:all,:include=>'user',
        :conditions=>['description like ? and users.enterprise_id=? and user_id=?',"%#{params[:crt_description]}%",@enterprise.id,@current_user.id])
    render :inline => '<%= auto_complete_result(@items, "description") %>'
  end
  
  def auto_complete_for_filter_expense_envelope
    @items=BulkExpense.find(:all,:include=>'user',
              :conditions=>['envelope like ? and users.enterprise_id=? and user_id=?',"%#{params[:crt_envelope]}%",@enterprise.id,@current_user.id])    
    render :inline => '<%= auto_complete_result(@items, "envelope") %>'
  end

  def update_params_filter
    update_params :default_scaffold_id => "bulk_expense", :default_sort => nil, :default_sort_direction => "asc"
  end

  def index
    redirect_to :action => 'list'
  end

  def return_to_main
    # If you have multiple scaffolds on the same view then you will want to change this to
    # to whatever controller/action shows all the views 
    # (ex: redirect_to :controller => 'AdminConsole', :action => 'index')
    redirect_to :controller => 'expenses', :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
  :redirect_to => { :controller => 'expenses', :action => 'list' }
  
  def list
   #Por defecto se ordena por fecha descendente
   params[:sort]='date'
   params[:sort_direction]='desc'
   render :layout => false
  end
  
  # All posts to change scaffold level variables like sort values or page changes go through this action
  def component_update
    @show_wrapper = false # don't show the outer wrapper elements if we are just updating an existing scaffold 
    if request.xhr?
      # If this is an AJAX request then we just want to delegate to the component to rerender itself
      component
    else
      # If this is from a client without javascript we want to update the session parameters and then delegate
      # back to whatever page is displaying the scaffold, which will then rerender all scaffolds with these update parameters
      return_to_main
    end
  end

  def component  
    @show_wrapper = true if @show_wrapper.nil?
    @sort_sql = BulkExpense.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{BulkExpense.table_name}.#{BulkExpense.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
  
    str_conditions = "user_id = :user_id"
    hs_conditions_params = { :user_id => @current_user.id}
    
        
    if params[:crt_date_from] && params[:expense]['crt_date_from(1i)']
      aux_time = Time.utc(params[:expense]['crt_date_from(1i)'],
        params[:expense]['crt_date_from(2i)'],params[:expense]['crt_date_from(3i)']) rescue nil
      if aux_time
        str_conditions << ' AND date >= :crt_date_from'
        hs_conditions_params[:crt_date_from] = aux_time.strftime("%Y-%m-%d")
      end
    end
    if params[:crt_date_to] && params[:expense]['crt_date_to(1i)']
      aux_time = Time.utc(params[:expense]['crt_date_to(1i)'],
        params[:expense]['crt_date_to(2i)'],params[:expense]['crt_date_to(3i)'])  rescue nil
      if aux_time
        str_conditions << ' AND date <= :crt_date_to'
        hs_conditions_params[:crt_date_to] = aux_time.strftime("%Y-%m-%d")
      end
    end
    unless params[:crt_description].blank?
      str_conditions << ' AND UPPER(expenses.description) LIKE :crt_description'
      hs_conditions_params[:crt_description] = "%#{params[:crt_description].upcase}%"
    end
    unless params[:crt_expense_type_id].blank?
      str_conditions << ' AND expenses.expense_type_id = :crt_expense_type_id'
      hs_conditions_params[:crt_expense_type_id] = params[:crt_expense_type_id]
    end
    unless params[:crt_project_id].blank?
      str_conditions << ' AND expenses.project_id = :crt_project_id'
      hs_conditions_params[:crt_project_id] = params[:crt_project_id]
    end
    unless params[:crt_envelope].blank?
      str_conditions << ' AND UPPER(expenses.envelope) LIKE :crt_envelope'
      hs_conditions_params[:crt_envelope] = "%#{params[:crt_envelope].upcase}%"
    end
    unless params[:crt_payment_type].blank?
      str_conditions << ' AND expenses.payment_type = :crt_payment_type'
      hs_conditions_params[:crt_payment_type] = params[:crt_payment_type]
    end
    if params[:crt_status].blank? 
      str_conditions << ' AND expenses.status = :crt_status '
      hs_conditions_params[:crt_status] = ExpenseStatus::PENDING        
    else
      unless params[:crt_status] == 'all'
        str_conditions << ' AND expenses.status = :crt_status '
        hs_conditions_params[:crt_status] = params[:crt_status]
      end
    end
    
    
    @paginator, @bulk_expenses = paginate(:bulk_expenses, :order => @sort_by, :per_page => GastosgemUtils::PAGE_SIZE,
                :include => [:project, :expense_type], :conditions => [str_conditions, hs_conditions_params])
    
    render :action => "component", :layout => false
  end

  def new
    @bulk_expense = BulkExpense.find(params[:id]) if params[:id]
    if @bulk_expense.nil?
      @bulk_expense = BulkExpense.new
      @bulk_expense.envelope = Expense.last_envelope(@current_user) || "#{AbbrMonthnames[Time.now.month]}_001"
    else
      @bulk_expense.id = nil
    end
        
    @successful = true

    return render(:action => 'new.rjs') if request.xhr?

    # Javascript disabled fallback
    if @successful
      @options = { :action => "create" }
      render :partial => "new", :layout => true
    else 
      return_to_main
    end
  end
  
  def create
    begin
      @bulk_expense = BulkExpense.new(params[:bulk_expense])
      @successful = @bulk_expense.save
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'create.rjs') if request.xhr?
    if @successful
      return_to_main
    else
      @options = { :scaffold_id => params[:scaffold_id], :action => "create" }
      render :partial => 'new_edit', :layout => true
    end
  end

  def edit
    begin
      @bulk_expense = BulkExpense.find(params[:id])      
      @successful = !@bulk_expense.nil?
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'edit.rjs') if request.xhr?

    if @successful
      @options = { :scaffold_id => params[:scaffold_id], :action => "update", :id => params[:id] }
      render :partial => 'new_edit', :layout => true
    else
      return_to_main
    end    
  end

  def update
    begin
      @bulk_expense = BulkExpense.find(params[:id])
      @bulk_expense.status = ExpenseStatus::PENDING if @bulk_expense.rejected? and @bulk_expense.user == @current_user
      @successful = @bulk_expense.update_attributes(params[:bulk_expense])      
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'update.rjs') if request.xhr?

    if @successful
      return_to_main
    else
      @options = { :action => "update" }
      render :partial => 'new_edit', :layout => true
    end
  end

  def destroy
    begin
      @successful = BulkExpense.find(params[:id]).destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'destroy.rjs') if request.xhr?
    
    # Javascript disabled fallback
    return_to_main
  end
  
  def cancel
    @successful = true
    
    return render(:action => 'cancel.rjs') if request.xhr?
    
    return_to_main
  end
  
  def expense_not_approved
    @expense = Expense.find(params[:id])
    if @expense.approved? and !@current_user.is_supervisor?
      flash[:error], @successful = "No se puede borrar o modificar un gasto aprobado", false 
      return render(:action => 'destroy.rjs') if request.xhr?
    end
    return true
  end
  
  #Expenses import
  def import
    return render(:action => 'import.rjs') if request.xhr?
    return_to_main
  end
  
  def cancel_import
    return_to_main unless request.xhr?
    
    render :update do |page|
      page.remove 'import_row' 
    end  
    
  end

  def import_csv
    flash[:error] = ''
    @successful = true
    # expense instance to store errors for all lines and show them on the view
    @bulk_expense = Expense.new
    file = params['csv']['file'] rescue nil
    line = 1
    if !file.blank? && file.size > 0
      begin
        input = FasterCSV.parse(file.read, {:col_sep => ',', 
                                            :headers => true,
                                            :header_converters => :downcase})
        if input.headers == CSV_HEADERS
          ActiveRecord::Base.transaction do
            input.each do |row|
              @expense_successful = true
              #logger.debug("Import expense line [#{row.join(',')}]")         
              unless row.blank?
                if import_expense row, line
                  @expense_successful =  @imported_expense.save!
                end
                logger.debug("Expense import #{@expense_successful} línea #{line}")
                @successful = false unless @expense_successful
              end
              line += 1
            end
            raise unless @successful
          end
        else
          @successful = false
          @bulk_expense.errors.add_to_base("Las cabeceras del fichero no son correctas. Han de ser #{CSV_HEADERS.join(', ')}")
        end
      rescue ActiveRecord::RecordInvalid
        @successful = false
        @bulk_expense.errors.add_to_base("Línea  #{line}. Error.")
      rescue
        @successful = false
        @bulk_expense.errors.add_to_base("Línea  #{line}.  #{$!.to_s}") if !($!.to_s.blank?)        
      end
    else
      @successful = false
      @bulk_expense.errors.add_to_base('El fichero es un campo obligatorio')
    end #if
    
    @options = { :scaffold_id => params[:scaffold_id], :action => "import_csv" }
    responds_to_parent do
      render :action => 'import_csv.rjs'
    end #responds_to_parent
  end #def      

  private

  def import_expense(row, line)
    @imported_expense = @current_user.expenses.build
    @imported_expense.date = GastosgemUtils.parse_date(row['fecha'].strip) rescue nil
    if @imported_expense.date.nil?
      @bulk_expense.errors.add_to_base("Línea #{line}. La fecha [#{row['fecha']}] no es válida.")
      @expense_successful = false
    end
    @imported_expense.description = row['concepto'].strip
    @imported_expense.amount = row['importe'].strip rescue nil
    if @imported_expense.amount.nil?
      @bulk_expense.errors.add_to_base("Línea #{line}. El importe [#{row['importe']}] no es válido.")
      @expense_successful = false
    end
    @imported_expense.envelope = row['sobre'].strip
    @imported_expense.payment_type = PaymentType.find_by_name(row['forma pago'].strip) rescue nil
    if @imported_expense.payment_type.nil?
      @bulk_expense.errors.add_to_base("Línea #{line}. No se encuentra la forma de pago [#{row['forma pago']}] en la aplicación.")
      @expense_successful = false
    end
    @imported_expense.expense_type = ExpenseType.find_by_description(row['tipo'].strip, :conditions => ['enterprise_id = ?', @current_user.enterprise_id]) rescue nil
    if @imported_expense.expense_type.nil?
      @bulk_expense.errors.add_to_base("Línea #{line}. No se encuentra el tipo de gastos [#{row['tipo']}] en la aplicación.")
      @expense_successful = false
    end
    @imported_expense.project = Project.find_by_name(row['proyecto'].strip, :conditions => ['enterprise_id = ?', @current_user.enterprise_id]) rescue nil
    if @imported_expense.project.nil?
      @bulk_expense.errors.add_to_base("Línea #{line}. No se encuentra el proyecto [#{row['proyecto']}] en la aplicación.")
      @expense_successful = false
    end
    @imported_expense.status = ExpenseStatus::PENDING
    @expense_successful
  end
  
end
