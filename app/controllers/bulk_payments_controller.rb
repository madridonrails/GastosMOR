require 'faster_csv'
class BulkPaymentsController < ApplicationController
  include AjaxScaffold::Controller
  
  after_filter :clear_flashes
  before_filter :update_params_filter
   
  before_filter :payer_required, :except => [:index,:list,:component,:component_update]
  
  prepend_before_filter :reset_filter_params, :only =>[ :list]
  
  #Comprueba que el id que viene pertenece a la empresa
  #before_filter :validate_enterprise, :only => [:edit,:update,:destroy]

  #Comprueba que el id pertenece al usuario logado
  before_filter :validate_payment,:only => [:edit,:destroy,:update]

  private

  CSV_HEADERS = ['fecha', 'cantidad', 'concepto', 'pagado a', 'descripción']
  
  #Valida que el pago que llega pertenece a la empresa del usuario logado.  
  def validate_enterprise
    payment = Payment.find(params[:id],:include=>'user',:conditions=>['users.enterprise_id=?',@enterprise.id],:select=>['id']) rescue nil
    !payment.blank?    
  end

  #Valida que el id que llega pertenece al usuario logado.  
  def validate_payment
    payment = @current_user.ordered_payments.find(params[:id]) rescue nil
    !payment.blank?
  end

  public  
        
  def auto_complete_for_bulk_payment_concept
    @items=Payment.find(:all,:include=>'user',
          :conditions=>['concept_for_sorting like ? and users.enterprise_id=?',"%#{params[:bulk_payment][:concept]}%",@enterprise.id])   
    render :inline => '<%= auto_complete_result(@items, "concept") %>'
  end    
  def update_params_filter
    update_params :default_scaffold_id => "bulk_payment", :default_sort => nil, :default_sort_direction => "asc"
  end

  def index
    redirect_to :action => 'list'
  end

  def return_to_main
    # If you have multiple scaffolds on the same view then you will want to change this to
    # to whatever controller/action shows all the views 
    # (ex: redirect_to :controller => 'AdminConsole', :action => 'index')
    redirect_to :controller => 'payments', :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
  :redirect_to => { :controller => 'payments', :action => 'list' }
  
  def list
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
    @page_payer = session[:page_payer]    
    
    
    @show_wrapper = true if @show_wrapper.nil?
    @sort_sql = BulkPayment.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{BulkPayment.table_name}.#{BulkPayment.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
 

    if @page_payer && (@current_user.is_administrator? || @current_user.is_gestor? )      
      #Pagina de pagos: si es un admin o un gestor entonces que vea TODOS los pagos de la empresa
      str_conditions = "users.enterprise_id = :enterprise_id"
      hs_conditions_params = { :enterprise_id => @enterprise.id}
    elsif @page_payer && @current_user.is_payer?         
      # Pagina de pagos: si es un pagador que vea los pagos hechos por el
      str_conditions = "ordered_by = :user_id"
      hs_conditions_params = { :user_id => @current_user.id}    
    else
      #Pagina general
      #si es un usuario que solo vea los suyos
      str_conditions = "user_id = :user_id"
      hs_conditions_params = { :user_id => @current_user.id}
    end   
 

    if params[:crt_date_from] && params[:payment]['crt_date_from(1i)']
      aux_time = Time.utc(params[:payment]['crt_date_from(1i)'],
        params[:payment]['crt_date_from(2i)'],params[:payment]['crt_date_from(3i)']) rescue nil
      if aux_time      
        str_conditions << ' AND date >= :crt_date_from'
        hs_conditions_params[:crt_date_from] = aux_time.strftime("%Y-%m-%d")
      end
    end
    if params[:crt_date_to] && params[:payment]['crt_date_to(1i)']
      aux_time = Time.utc(params[:payment]['crt_date_to(1i)'],
        params[:payment]['crt_date_to(2i)'],params[:payment]['crt_date_to(3i)'])  rescue nil
      if aux_time    
        str_conditions << ' AND date <= :crt_date_to'
        hs_conditions_params[:crt_date_to] = aux_time.strftime("%Y-%m-%d")
      end
    end
    unless params[:crt_user_id].blank?
      str_conditions << ' AND payments.user_id = :crt_user_id'
      hs_conditions_params[:crt_user_id] = params[:crt_user_id]
    end
    unless params[:crt_ordered_by].blank?
      str_conditions << ' AND payments.ordered_by = :crt_ordered_by'
      hs_conditions_params[:crt_ordered_by] = params[:crt_ordered_by]
    end
    
    @paginator, @bulk_payments = paginate(:bulk_payments, :order => @sort_by, :per_page => GastosgemUtils::PAGE_SIZE, :include => [:user], :conditions => [str_conditions, hs_conditions_params])
    
    render :action => "component", :layout => false
  end

  def new
    @page_payer = session[:page_payer]
    @bulk_payment = BulkPayment.find(params[:id]) if params[:id]
    if @bulk_payment.nil?
      @bulk_payment = BulkPayment.new
    else
      @bulk_payment.id = nil
    end    
    
    @successful = true

    return render(:action => 'new.rjs') if request.xhr?

    # Javascript disabled fallback
    if @successful
      @options = { :action => "create" }
      render :partial => "new_edit", :layout => true
    else 
      return_to_main
    end
  end
  
  def create
    @page_payer = session[:page_payer]
    begin
      @bulk_payment = BulkPayment.new(params[:bulk_payment])
      @bulk_payment.orderer = @current_user
      @successful = @bulk_payment.save
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
    @page_payer = session[:page_payer]
    begin
      @bulk_payment = BulkPayment.find(params[:id])
      @successful = !@bulk_payment.nil?
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
    @page_payer = session[:page_payer]
    begin
      @bulk_payment = BulkPayment.find(params[:id])
      @bulk_payment.ordered_by = @current_user.id
      @successful = @bulk_payment.update_attributes(params[:bulk_payment])
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
    @page_payer = session[:page_payer]
    begin
      @successful = BulkPayment.find(params[:id]).destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'destroy.rjs') if request.xhr?
    
    # Javascript disabled fallback
    return_to_main
  end
  
  def cancel
    @page_payer = session[:page_payer]
    @successful = true
    
    return render(:action => 'cancel.rjs') if request.xhr?
    
    return_to_main
  end
  
  #Payments import
  def import
    return render(:action => 'import.rjs') if request.xhr?
    return_to_main
  end
  
  def cancel_import
    return_to_main if !request.xhr?
    
    render :update do |page|
      page.remove 'import_row' 
    end  
    
  end
  
  
  def import_csv
    flash[:error] = ''
    @successful = true
    # payment instance to store errors for all lines and show them on the view
    @bulk_payment = Payment.new
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
              @payment_successful = true
              # logger.debug("Import expense line [#{row.join(',')}]")
              unless row.blank?
                if import_payment row, line
                  @successful = @imported_payment.save!
                end
                logger.debug("Payment import #{@payment_successful} línea #{line}")
                @successful = false unless @payment_successful
              end
              line += 1
            end
            raise unless @successful
          end
        else
          @successful = false
          @bulk_payment.errors.add_to_base("Las cabeceras del fichero no son correctas. Han de ser #{CSV_HEADERS.join(', ')}")
        end
      rescue ActiveRecord::RecordInvalid
        @successful = false
        @bulk_payment.errors.add_to_base("Línea #{line}. Error ")
      rescue
        @successful = false
        @bulk_payment.errors.add_to_base("Línea  #{line}.  #{$!.to_s}") if !($!.to_s.blank?)
      end
    else
      @successful = false
      @bulk_payment.errors.add_to_base('El fichero es un campo obligatorio')
    end #if

    @options = { :scaffold_id => params[:scaffold_id], :action => "import_csv" }
    responds_to_parent do
      render :action => 'import_csv.rjs'
    end #responds_to_parent
  end #def

  private

  def import_payment(row, line)
    @imported_payment = @current_user.ordered_payments.build
    @imported_payment.date= GastosgemUtils.parse_date(row['fecha'].strip) rescue nil
    if @imported_payment.date.nil?
      @bulk_payment.errors.add_to_base("Línea #{line}. La fecha [#{row['fecha']}] no es válida.")
      @payment_successful = false
    end
    @imported_payment.amount= row['cantidad'].strip rescue nil
    if @imported_payment.amount.nil?
      @bulk_payment.errors.add_to_base("Línea #{line}. La cantidad [#{row['cantidad']}] no es válida.")
      @payment_successful = false
    end
    @imported_payment.concept= row['concepto'].strip
    @imported_payment.user = User.find_by_email(row['pagado a'].strip, :conditions => ['enterprise_id = ?', @current_user.enterprise_id]) rescue nil
    if @imported_payment.user.nil?
      @bulk_payment.errors.add_to_base("Línea #{line}. No se encuentra el usuario con email [#{row['pagado a']}] en la aplicación.")
      @payment_successful = false
    end
    @imported_payment.description= row['descripción'].strip
    @payment_successful
  end

end
