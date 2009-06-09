class EnterprisesController < ApplicationController
  include AjaxScaffold::Controller
  
  after_filter :clear_flashes
  before_filter :admin_site_required
  before_filter :update_params_filter
  
  prepend_before_filter :reset_filter_params, :only =>[ :list]
   

private

  def verify_credentials
    redirect_to :controller => 'admin' unless @current_user.is_admin_site? 
  end

public
  def update_params_filter
    update_params :default_scaffold_id => "enterprise", :default_sort => nil, :default_sort_direction => "asc"
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

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => 'list' }

  def list
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
    @sort_sql = Enterprise.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Enterprise.table_name}.#{Enterprise.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    
    str_and=''
    str_conditions=''
    hs_conditions_params={}
    
    unless params[:crt_name].blank?       
        str_conditions << ' enterprises.short_name LIKE :crt_name'
        hs_conditions_params[:crt_name] = "%#{params[:crt_name]}%"
        str_and = ' AND '
    end
    unless params[:crt_is_active].blank? 
        if params[:crt_is_active] == '1'  
          str_conditions <<  str_and << ' users.activation_code IS NULL'        
        else
          str_conditions <<  str_and << ' users.activation_code IS NOT NULL'        
        end
        str_and = ' AND '
    end
    unless params[:crt_is_blocked].blank?
      str_conditions << str_and << ' enterprises.is_blocked = :crt_is_blocked'
      hs_conditions_params[:crt_is_blocked] = params[:crt_is_blocked]
      str_and = ' AND '
    end
    if params[:crt_date_from] && params[:filter]['crt_date_from(1i)']
      aux_time = Time.utc(params[:filter]['crt_date_from(1i)'],
      params[:filter]['crt_date_from(2i)'],params[:filter]['crt_date_from(3i)']) rescue nil
      if aux_time
        str_conditions << str_and << ' enterprises.created_at >= :crt_date_from '
        hs_conditions_params[:crt_date_from] = aux_time.strftime("%Y-%m-%d")
        str_and = ' AND '
      end
    end
    if params[:crt_date_to] && params[:filter]['crt_date_to(1i)']
      aux_time = Time.utc(params[:filter]['crt_date_to(1i)'],
      params[:filter]['crt_date_to(2i)'],params[:filter]['crt_date_to(3i)'])  rescue nil
      if aux_time
        str_conditions << str_and << ' enterprises.created_at <= :crt_date_to '
        #Se le suman los segundos correspondientes a un día porque si no el dia hasta no lo encuentra
        #debido a las horas
        hs_conditions_params[:crt_date_to] = (aux_time+86400).strftime("%Y-%m-%d")
      end
    end
    
    if str_conditions.blank?     
      @paginator, @enterprises = paginate(:enterprises,  :order => @sort_by, :per_page => GastosgemUtils::PAGE_SIZE,:include=>[:account_owner])
    else
      @paginator, @enterprises = paginate(:enterprises,  :order => @sort_by, :per_page => GastosgemUtils::PAGE_SIZE,:include=>[:account_owner],:conditions => [str_conditions, hs_conditions_params])
    end
    
    render :action => "component", :layout => false
  end
  
  def edit
    begin
      @enterprise = Enterprise.find(params[:id])
      @successful = !@enterprise.nil?
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
      @enterprise = Enterprise.find(params[:id])
      @successful = @enterprise.update_attributes(params[:enterprise])      
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

  def purge
    begin
      @successful = Enterprise.find(params[:id]).purge
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    return render(:action => 'purge.rjs') if request.xhr?
    
    # Javascript disabled fallback
    return_to_main
  end
  
  def cancel
    @successful = true
    
    return render(:action => 'cancel.rjs') if request.xhr?
    
    return_to_main
  end
  
end
