class SignupController < ApplicationController

  layout 'public'
  
  skip_before_filter :check_authentication
  skip_before_filter :redirect_if_www

  def index
    redirect_to(:controller => 'public', :action => 'home')
  end
  
  def create_new_user
    unless request.post?
      @enterprise = Enterprise.new
      @enterprise.country_id=71 #Por defecto sale seleccionado España
      return
    end
    signup
  end

  def success
  end

  def activated
  end
  
  def activate
    flash.clear
    activator = params[:id] || params[:activation_code]
    return unless activator
    @user = User.find_by_activation_code(activator)
    if @user and @user.activate
      add_default_project_and_expense_type
      begin
        send_activated_mail
      rescue Exception => e
        flash[:error] = "La cuenta ha sido activada, pero no hemos podido enviarte el mensaje de confirmación. Por favor, contacta con nosotros."	
      end
      redirect_to({:action => 'activated', :id => @user.enterprise.short_name})
    else
      flash[:error] = "No se ha podido activar la cuenta.  Por favor verifica los datos."
    end
  end

  private

  def signup
    @enterprise = Enterprise.new(params[:enterprise])
    @enterprise.cif ||= ''
    
    @account_owner = User.new(params[:account_owner])
    @account_owner.is_administrator = true
    @account_owner.is_supervisor = true
    @account_owner.is_payer = true
    # Assign enterprise to user, so that validation of enterprise_id will not fail because of :if condition
    @account_owner.enterprise = @enterprise
    
    unless params[:accept_terms]
      flash[:error] = "Has de aceptar las condiciones de uso"
      return
    end

    if @enterprise.valid? && @account_owner.valid?
      complete_signup      
    else
      @enterprise.errors.full_messages.each { |msg| flash[:error] = msg }
      render :action => :create_new_user
    end
  end

  def complete_signup
    Enterprise.transaction do
      @enterprise.save!
      @enterprise.users << @account_owner
      @enterprise.account_owner = @account_owner
      @enterprise.save!
    end
    begin
      send_activation_mail
    rescue Exception => e
      flash[:error] = "No hemos podido enviarte el mensaje de activación por correo electrónico\n.Por favor, contacta con nosotros."
    end
    redirect_to :action => 'success'
  end

  def add_default_project_and_expense_type
    default_project = Project.create_default(@user)
    @user.enterprise.projects << default_project
    @user.supervised_projects << default_project
    default_expense_types = ExpenseType.create_default @user.enterprise
    @user.enterprise.expense_types << default_expense_types
  end

  def send_activation_mail
    activation_page = url_for(:action => 'activate')
    activation_link = url_for(:action => 'activate', :id => @account_owner.activation_code)
    SignupMailer.deliver_activation_mail(@account_owner, activation_link, activation_page)
  end

  def send_activated_mail
    access_link = account_url(@user.enterprise.short_name)
    SignupMailer.deliver_activated_mail(@user, access_link)
  end

end
