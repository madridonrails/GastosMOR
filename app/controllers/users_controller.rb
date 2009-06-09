require 'faster_csv'

class UsersController < ApplicationController
  include AjaxScaffold::Controller
  
  before_filter :admin_required, :except => [:profile,:save_profile,:list_supervised,:component_supervised,:component_update_supervised]
  before_filter :supervisor_required, :only => [:list_supervised,:component_supervised,:component_update_supervised]
  #Comprueba que el id que viene pertenece a la empresa
  before_filter :validate_enterprise, :only => [:edit,:update,:destroy]
  prepend_before_filter :reset_filter_params, :only =>[:list_supervised, :list]
  
  after_filter :clear_flashes
  before_filter :update_params_filter
 
  private
  
  CSV_HEADERS = ['email', 'nombre', 'apellidos', 'password', 'supervisor', 'administrador', 'pagador', 'gestor', 'email supervisor']
  
  #Valida que el id que llega pertenece a la empresa del usuario logado.
  def validate_enterprise
    user = @enterprise.users.find(params[:id]) rescue nil
    !user.blank?
  end    

  def find_and_paginate_users(conditions)
    @show_wrapper = true if @show_wrapper.nil?
    @sort_sql = User.scaffold_columns_hash[current_sort(params)].sort_sql rescue nil
    unless @sort_sql == 'users.balance'
      @sort_by = @sort_sql.nil? ? "#{User.table_name}.#{User.primary_key} asc" : @sort_sql  + " " + current_sort_direction(params)
      @paginator, @users = paginate(:users, :conditions => conditions, :order => @sort_by, :per_page => GastosgemUtils::PAGE_SIZE)
    else
      @all_users = User.find(:all, :conditions => conditions, :include => [:expenses, :payments])
      @all_users = @all_users.sort_by { |u| u.balance }
      @all_users.reverse! if current_sort_direction(params) == "desc"
      @paginator, @users = paginate_collection @all_users, :per_page => GastosgemUtils::PAGE_SIZE
    end
  end
 
  public  

  def update_params_filter
    update_params :default_scaffold_id => "user", :default_sort => nil, :default_sort_direction => "asc"
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
    find_and_paginate_users ['enterprise_id = ?', @enterprise.id]
    render :action => "component", :layout => false
  end
  
  
  def list_supervised     
  end
  
  def component_update_supervised
    @show_wrapper = false # don't show the outer wrapper elements if we are just updating an existing scaffold 
    if request.xhr?
      # If this is an AJAX request then we just want to delegate to the component to rerender itself
      component_supervised
    else
      # If this is from a client without javascript we want to update the session parameters and then delegate
      # back to whatever page is displaying the scaffold, which will then rerender all scaffolds with these update parameters
      return_to_main
    end
  end
  
  def component_supervised
    find_and_paginate_users ['enterprise_id = ? and supervisor_id=?', @enterprise.id, @current_user.id]
    render :action => "component_supervised", :layout => false
  end
    
  def new
    @user = User.new
    @user.supervisor = @enterprise.users.find(:first, :order => "id DESC").supervisor || @enterprise.account_owner
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
    @successful = true
    begin
      @user = User.new(params[:user])            
      if @user && @current_user.enterprise.users << @user
        @user.activate        
      end
      @successful=@user.save
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
      @user = User.find(params[:id])
      @successful = !@user.nil?
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
      @user = User.find(params[:id])
      params[:user][:is_blocked] = false if @user.is_account_owner?
      @successful = @user.update_attributes(params[:user])
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
      @successful = User.find(params[:id])
      user = @successful
      if user && user.is_account_owner?
        flash[:notice] = 'Usuario no puede ser borrado'
      else
        user.destroy if user
        flash[:notice] = 'Usuario borrado satisfactoriamente'
      end
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
  
  def profile
    begin
      @user = User.find(@current_user.id)
      @successful = !@user.nil?
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    
    render :action =>'profile'
  end
  
  def save_profile
    return profile if !params[:clear].blank?
    flash[:notice]=nil
    begin
      @user = User.find(@current_user.id)
      old_passwd = params[:old_password]
      passwd = params[:user][:password]      
      if (!passwd.blank? && !@user.authenticated?(old_passwd))
        logger.debug("password antiguo incorrecto")  
        @user.errors.add_to_base('Password antiguo incorrecto')                          
      else      
        @successful = @user.update_attributes(params[:user])  
        logger.debug("#{@successful} errores actualizando perfil #{@user.errors.full_messages}") 
        flash[:notice] = 'Informacion actualizada correctamente' if @successful              
      end            
    rescue  
      @successful  = $!.to_s, false
    end
    
    render :action =>'profile'
    
  end
  
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
    # user instance to store errors for all lines and show them on the view
    @user = User.new
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
              @user_successful = true
              #logger.debug("Import user line [#{row.join(',')}]")         
              unless row.blank?
                if import_user row, line
                  @user_successful = @imported_user.save!
                  @imported_user.activate if @user_successful
                end
                logger.debug("User import #{@user_successful} línea #{line}")
                @successful = false unless @user_successful
              end                                               
              line += 1
            end
            raise unless @successful
          end
        else
          @successful = false
          @user.errors.add_to_base("Las cabeceras del fichero no son correctas. Han de ser #{CSV_HEADERS.join(', ')}")
        end
      rescue ActiveRecord::RecordInvalid
        @successful = false
        @user.errors.add_to_base("Línea #{line}. Error.")
      rescue
        @successful = false
        @user.errors.add_to_base("Línea #{line}. #{$!.to_s}") if !($!.to_s.blank?)
      end
    else
      @successful = false
      @user.errors.add_to_base('El fichero es un campo obligatorio')
    end                   

    @options = { :scaffold_id => params[:scaffold_id], :action => "import_csv" }    
    responds_to_parent do
      render :action => 'import_csv.rjs'
    end                  
  end

  private

  def import_user(row, line)
    existent_user = User.find_by_email(row['email'].strip, :conditions => ['enterprise_id = ?', @current_user.enterprise_id]) rescue nil
    unless existent_user.nil?
      @user.errors.add_to_base("Línea #{line}. Ya existe un usuario con email [#{row['email']}]")
      @user_successful = false
      return
    end
    @imported_user = @enterprise.users.build
    ['supervisor', 'administrador', 'pagador', 'gestor'].each do |column|
      unless ['0', '1'].include? row[column].strip
        @user.errors.add_to_base("Línea #{line}. La columna #{column} puede contener los valores 0 y 1, [#{row[column]}] no es válido")
        @user_successful = false
      end
    end
    @imported_user.email = @imported_user.email_confirmation = row['email'].strip
    @imported_user.first_name = row['nombre'].strip
    @imported_user.last_name = row['apellidos'].strip
    @imported_user.password = @imported_user.password_confirmation = row['password'].strip
    @imported_user.is_supervisor = row['supervisor'].strip
    @imported_user.is_administrator = row['administrador'].strip
    @imported_user.is_payer = row['pagador'].strip
    @imported_user.is_gestor = row['gestor'].strip
    @imported_user.supervisor = User.find_by_email(row['email supervisor'].strip, :conditions => ['enterprise_id = ? and is_supervisor = ?', @current_user.enterprise_id, 1]) rescue nil
    if @imported_user.supervisor.nil?
      @user.errors.add_to_base("Línea #{line}. No se encuentra el usuario con email [#{row['email supervisor']}] y perfil supervisor en la aplicación.")
      @user_successful = false
    end
    @user_successful
  end

end
