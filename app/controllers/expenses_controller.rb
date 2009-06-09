class ExpensesController < ApplicationController
  include AjaxScaffold::Controller
  
  before_filter :supervisor_or_gestor_required, :only =>[:list_pending, :listing_pending]
  before_filter :expense_not_approved, :only =>[:edit, :destroy]
  before_filter :remember_last_list ,  :only =>[:list,:index,:list_pending]
  before_filter :admin_required, :only =>[:list_expense_manager,:delete,:show ]
  prepend_before_filter :reset_filter_params, :only =>[:list_expense_manager, :list_pending, :list]
  
  after_filter :clear_flashes
  before_filter :update_params_filter
  
  #Comprueba que el id que viene pertenece a la empresa
  before_filter :validate_enterprise, :only => [:show,:edit,:update,:approve,:reject,:delete]
  
  #Comprueba que el usuario logado puede actuar sobre el id
  before_filter :validate_supervisor, :only =>[:approve,:reject]
  before_filter :validate_supervisor_or_admin, :only =>[:edit]
  
  private
  
  #Valida que el id que llega pertenece a la empresa del usuario logado.
  def validate_enterprise
    expense = Expense.find(params[:id],:include=>'user',:conditions=>['users.enterprise_id=?',@enterprise.id],:select=>['id']) rescue nil
    !expense.blank?
  end
  #Valida que el usuario logado y sea supervisor puede manipular al id que llega
  def validate_supervisor
    return false unless @current_user.is_supervisor?
    expense = Expense.find(params[:id]) rescue nil
    return false if expense.blank?
    expense.user.supervisor_id == @current_user.id || expense.project.supervisor_id == @current_user.id
  end
  #Valida que el usuario logado y sea supervisor puede manipular al id que llega
  def validate_supervisor_or_admin    
    return validate_supervisor if @current_user.is_supervisor?
    return @current_user.is_administrator?
  end
  
  def build_conditions
    str_conditions = ''
    arr_conditions_params = []
    
    if params[:crt_date_from] && params[:expense]['crt_date_from(1i)']
      aux_time = Time.utc(params[:expense]['crt_date_from(1i)'],
      params[:expense]['crt_date_from(2i)'],params[:expense]['crt_date_from(3i)']) rescue nil
      if aux_time
        str_conditions << ' AND date >= ? '
        arr_conditions_params << aux_time.strftime("%Y-%m-%d")
      end
    end
    if params[:crt_date_to] && params[:expense]['crt_date_to(1i)']
      aux_time = Time.utc(params[:expense]['crt_date_to(1i)'],
      params[:expense]['crt_date_to(2i)'],params[:expense]['crt_date_to(3i)'])  rescue nil
      if aux_time
        str_conditions << ' AND date <= ? '
        arr_conditions_params <<  aux_time.strftime("%Y-%m-%d")
      end
    end
    unless params[:crt_description].blank?
      str_conditions << ' AND UPPER(expenses.description) LIKE ? '
      arr_conditions_params << "%#{params[:crt_description].upcase}%"
    end
    unless params[:crt_expense_type_id].blank?
      str_conditions << ' AND expenses.expense_type_id = ? '
      arr_conditions_params << params[:crt_expense_type_id]
    end
    unless params[:crt_project_id].blank?
      str_conditions << ' AND expenses.project_id = ? '
      arr_conditions_params << params[:crt_project_id]
    end
    unless params[:crt_envelope].blank?
      str_conditions << ' AND UPPER(expenses.envelope) LIKE ? '
      arr_conditions_params << "%#{params[:crt_envelope].upcase}%"
    end
    unless params[:crt_payment_type].blank?
      str_conditions << ' AND expenses.payment_type = ? '
      arr_conditions_params << params[:crt_payment_type]
    end
    unless params[:crt_user_id].blank?
      str_conditions << ' AND expenses.user_id = ? '
      arr_conditions_params << params[:crt_user_id]
    end
    if params[:crt_status].blank? 
      str_conditions << ' AND expenses.status = ? '
      arr_conditions_params << ExpenseStatus::PENDING        
    else
      unless params[:crt_status] == 'all'
        str_conditions << ' AND expenses.status = ? '
        arr_conditions_params << params[:crt_status]
      end
    end
      
    @str_conditions = str_conditions
    @arr_conditions_params = arr_conditions_params
  end
  
  public    

  def auto_complete_for_expense_envelope
    @items=Expense.find(:all,:include=>'user',
            :conditions=>['envelope like ? and users.enterprise_id=? and user_id=?',"%#{params[:expense][:envelope]}%",@enterprise.id,@current_user.id])    
    render :inline => '<%= auto_complete_result(@items, "envelope") %>'
  end
  def auto_complete_for_expense_description
    @items=Expense.find(:all,:include=>'user',
    :conditions=>['description like ? and users.enterprise_id=? and user_id=?',"%#{params[:expense][:description]}%",@enterprise.id,@current_user.id])    
    render :inline => '<%= auto_complete_result(@items, "description") %>'
  end

  # First get the supervised projects, then we make a select of all the expenses from our supervised users and projects
  def auto_complete_for_filter_expense_pending_description
      project_ids = (@current_user.supervised_projects.nil? || @current_user.supervised_projects.empty? ) ? '' : (@current_user.supervised_projects.collect {|p| p.id}.flatten)
                          
    @items=BulkExpense.find(:all,:include=> [:user, :project],
        :conditions=>['expenses.description like ? and users.enterprise_id=? and (users.supervisor_id= ? OR projects.id IN (?))',"%#{params[:crt_description]}%",@enterprise.id,@current_user.id, project_ids])
    render :inline => '<%= auto_complete_result(@items, "description") %>'
  end
  
  # First get the supervised projects, then we make a select of all the expenses from our supervised users and projects
  def auto_complete_for_filter_expense_pending_envelope
      project_ids = (@current_user.supervised_projects.nil? || @current_user.supervised_projects.empty? ) ? '' : (@current_user.supervised_projects.collect {|p| p.id}.flatten)
    @items=BulkExpense.find(:all,:include=> [:user, :project] ,
              :conditions=>['expenses.envelope like ? and users.enterprise_id=? and (users.supervisor_id=? OR projects.id IN (?))',"%#{params[:crt_envelope]}%",@enterprise.id,@current_user.id, project_ids])    
    render :inline => '<%= auto_complete_result(@items, "envelope") %>'
  end
  
  def update_params_filter
    update_params :default_scaffold_id => "expense", :default_sort => nil, :default_sort_direction => "asc"
  end
  
  def index
    redirect_to :action => 'list'
  end
  
  def return_to_main
    # If you have multiple scaffolds on the same view then you will want to change this to
    # to whatever controller/action shows all the views 
    # (ex: redirect_to :controller => 'AdminConsole', :action => 'index')
    redirect_to :action => 'list'
  end
  
  def list
    @status_combo = ExpenseStatus.combo            
    if !request.xhr?
      @status_selected=ExpenseStatus::PENDING  #Por defecto mostrar los gastos pendientes
    end
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
   
  # All posts to change scaffold level variables like sort values or page changes go through this action
  def component_update_expense_manager
    @show_wrapper = false # don't show the outer wrapper elements if we are just updating an existing scaffold 
    if request.xhr?
      # If this is an AJAX request then we just want to delegate to the component to rerender itself
      component_expense_manager
    else
      # If this is from a client without javascript we want to update the session parameters and then delegate
      # back to whatever page is displaying the scaffold, which will then rerender all scaffolds with these update parameters
      redirect_to(:action => :list_expense_manager) 
    end
  end

  def component  
    build_conditions
    @show_wrapper = true if @show_wrapper.nil?
    @sort_sql = Expense.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Expense.table_name}.#{Expense.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)  
    
    str_conditions = nil
    conditions_params = nil
    # The variables @str_conditions and @arr_conditions_params  come from list_pending action
    if @current_user.is_gestor?
      str_conditions = 'users.enterprise_id = ? and expenses.status = ? '
      str_conditions += @str_conditions || ''    
      arr_conditions_params = [ str_conditions,@current_user.enterprise_id,ExpenseStatus::APPROVED ]          
      arr_conditions_params += @arr_conditions_params || []
    else    
      project_ids = (@current_user.supervised_projects.nil? || @current_user.supervised_projects.empty? ) ? '' : (@current_user.supervised_projects.collect {|p| p.id}.flatten)
                           
      str_conditions = "(users.supervisor_id = ? OR projects.id IN (?) )"          
      str_conditions += @str_conditions || ' AND expenses.status = ?' #Por defecto mostrar los gastos pendientes
            

      #we concatenate in the conditions array the query string with ? placemarkers, and then the
      #values for the conditions, which are user_id, project_ids and then all the values from
      #the criteria coming in the arr_conditions_params parameter
      arr_conditions_params = [ str_conditions, @current_user.id,  project_ids]
      arr_conditions_params += @arr_conditions_params || [ExpenseStatus::PENDING ] #Por defecto mostrar los gastos pendientes
    end
    @paginator, @expenses = paginate(:expenses, :order => @sort_by, :per_page => GastosgemUtils::PAGE_SIZE,
                                     :include => [:project, :user, :expense_type], 
                                     :conditions =>  arr_conditions_params )      
    
    render :action => "component", :layout => false
  end
   
  def component_expense_manager 
    build_conditions
    @show_wrapper = true if @show_wrapper.nil?
    @sort_sql = Expense.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Expense.table_name}.#{Expense.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)  
    
    str_conditions = nil
    conditions_params = nil
    # The variables @str_conditions and @arr_conditions_params  come from list_pending action
    str_conditions = 'users.enterprise_id = ? '
    str_conditions += @str_conditions || ''    
    arr_conditions_params = [ str_conditions,@current_user.enterprise_id ]          
    arr_conditions_params += @arr_conditions_params || []
    
    @paginator, @expenses = paginate(:expenses, :order => @sort_by, :per_page => GastosgemUtils::PAGE_SIZE,
                                     :include => [:project, :user, :expense_type], 
                                     :conditions =>  arr_conditions_params )      
    
    render :action => "component_expense_manager", :layout => false
  end

  def edit
    begin
      @expense = Expense.find(params[:id])
      @successful = !@expense.nil?
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    @allow_reject = params[:allow_reject] if @current_user.is_supervisor? || @current_user.is_account_owner?
    return render(:action => 'edit.rjs') if request.xhr?
    
    if @successful
      @options = { :scaffold_id => params[:scaffold_id], :action => "update", :id => params[:id] }
      render :partial => 'new_edit', :layout => true
    else
      return_to_main
    end    
  end
 
  # This action is used in "adm. de gastos" ONLY for admin
  def show
    begin
      @expense = Expense.find(params[:id])
      @successful = !@expense.nil?
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
      
    return render(:action => 'edit.rjs') if request.xhr? #Only can be called by xmlhttprequest
    
    return_to_main
  end

  def update
    begin
      @expense = Expense.find(params[:id])
      @successful = @expense.update_attributes(params[:expense])
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
 
  def cancel
    @successful = true
    
    return render(:action => 'cancel.rjs') if request.xhr?
    
    return_to_main
  end

  def list_pending
    # For the filter
    @user_combo = get_user_list_by_enterprise(@current_user, @enterprise)
    @status_combo = ExpenseStatus.combo
    
    
    #if we are getting called via ajax, we have to check if we are getting any search criteria and
    #then we have to compose the query string and the values array
    #we pass the string and array as instance variables
    if request.xhr?
      build_conditions      
      component
    else
      @status_selected=ExpenseStatus::PENDING  #Por defecto mostrar los gastos pendientes
    end  
  end

  def list_expense_manager
    # For the filter
    @user_combo = get_user_list_by_enterprise(@current_user, @enterprise)
    @status_combo = ExpenseStatus.combo
    #if we are getting called via ajax, we have to check if we are getting any search criteria and
    #then we have to compose the query string and the values array
    #we pass the string and array as instance variables
    if request.xhr?
      build_conditions
      component_expense_manager
    end  
  end
 
  def approve
    begin
      @expense = Expense.find(params[:id])
      if @expense.pending?
        @expense.status = ExpenseStatus::APPROVED
        @expense.revised_by = @current_user.id
        @expense.revised_at = Time.now.to_s(:db)
        flash[:notice] = @expense.save ? 'Gasto aprobado satisfactoriamente' : 'Error al aprobar gasto'
      else
        flash[:notice] = 'Error al aprobar el gasto. Debe estar pendiente para poder ser aprobado'
      end
    rescue Exception => e
      logger.error(e)
      flash[:notice] = 'Se intentó aprobar un gasto inexistente'
    end 
    
    return render(:action => 'approve.rjs') if request.xhr?
    
    redirect_to :action => 'list_pending'
  end

  def reject
    begin
      @expense = Expense.find(params[:id]) 
      @expense.status = ExpenseStatus::REJECTED
      @expense.revised_by = @current_user.id
      @expense.revised_at = Time.now.to_s(:db)
      logger.debug(" IDE del usuario #{@current_user.id} ")
      if @expense.update_attributes(params[:expense]) 
        @expense.save!
        @successful = true
      end
    rescue Exception => e
      @successful=false
      logger.error(e)
      @expense.errors.add_to_base('Se produjo un error al denegar el gasto')
    end 
    
    return render(:action => 'reject.rjs') if request.xhr?
    
    redirect_to :action => 'list_pending'
  end   
  
  def delete
    begin
      @successful = Expense.find(params[:id]).destroy
    rescue Exception => e
      flash[:error], @successful  = $!.to_s, false
    end

    return render(:action => 'delete.rjs') if request.xhr?
    redirect_to :action => 'list_expense_manager'
  end

  def expense_not_approved
    @expense = Expense.find(params[:id])
    redirect_to :action => 'list' if @expense.approved? and !@current_user.is_supervisor?
  end
  
  def back_to_previous_list
    redirect_to :action => session[:back_to]
    session[:back_to] = nil
  end
    
  private
  
  def remember_last_list
    session[:back_to]= session[:intended_action]
  end
  
end
