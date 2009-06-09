class ProjectsController < ApplicationController
  include AjaxScaffold::Controller
  
  after_filter :clear_flashes
  before_filter :admin_required
  before_filter :update_params_filter
  
  #Comprueba que el id que viene pertenece a la empresa
  before_filter :validate_enterprise, :only => [:edit,:update,:destroy]

private
  #Valida que el id que llega pertenece a la empresa del usuario logado.
  def validate_enterprise
    project = @enterprise.projects.find(params[:id]) rescue nil
    !project.blank?
  end
  
  def verify_credentials
    redirect_to :controller => 'admin' unless @current_user.is_administrator? 
  end

public
  def update_params_filter
    update_params :default_scaffold_id => "project", :default_sort => nil, :default_sort_direction => "asc"
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
    @sort_sql = Project.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    @sort_by = @sort_sql.nil? ? "#{Project.table_name}.#{Project.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
    @paginator, @projects = paginate(:projects, :conditions => ['enterprise_id = ?', @enterprise.id], :order => @sort_by, :per_page => GastosgemUtils::PAGE_SIZE)
    
    render :action => "component", :layout => false
  end

  def new
    @project = Project.new
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
    begin
      @project = Project.new(params[:project])
      @project.enterprise_id=@enterprise.id
      @successful = @project.save
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
      @project = Project.find(params[:id])
      @successful = !@project.nil?
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
      @project = Project.find(params[:id])
      @successful = @project.update_attributes(params[:project])
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
      @successful = Project.find(params[:id]).destroy
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
  
end
