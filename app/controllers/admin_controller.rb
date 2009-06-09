class AdminController < ApplicationController

  skip_before_filter :check_authentication, :only => [ :signin, :index, :new_password ]
  before_filter :admin_site_required,:only=>[:backoffice]
  
  layout 'public'
  
  def index
    redirect_to :action => 'signin'
  end 
 
  def signin
    @user = User.new  
    @user.email = params[:user][:email] rescue ''
    if request.post?
      if !@enterprise.account_owner.activation_code.blank?
        flash[:notice] = 'Empresa no activada, activela utilizando el código de activación proporcionado por correo'
        render :action=>'signin'
      elsif @enterprise.is_blocked?
        flash[:notice] = 'Empresa bloqueada, contacte con el administrador'
        render :action=>'signin'
      elsif user = User.authenticate(@user.email.to_s, params[:password].to_s, @enterprise)
        session[:user] = user.id 
        redirect_back_or_default(user)
      else
        
        flash[:notice] = 'Usuario o password incorrecto'
        render :action=>'signin'
      end
    end
  end

  def signout
    reset_session
    redirect_to :action => 'signin'
  end

  def home
    redirect_to :action=>'user'
  end

  # Renders the form that asks for an email to send a new password to, if
  # responding to GET. Sets a new password and sends it by email on POST.
  #
  # We validate the received email corresponds to some user in the
  # database, and we check for mailer exceptions. If everything looks fine
  # once the mail has been sent we redirect to the login page.
  def new_password  
    @user = User.new  
    @user.email = params[:user][:email] rescue ''          
    if @user.email.blank?
      logger.debug("No email")
      flash[:error] = 'Por favor facilita un email'
      return render(:action=>'signin')
    end   
    
    user = User.find(:first,:conditions=>['email=? and enterprise_id=?',@user.email,@enterprise.id])
    if not user
      logger.debug("no usuario")
      flash[:error] =  "No hay ningún usuario con email #{@user.email}"
      return render(:action=>'signin')
    end

    begin
      new_passwd=user.set_new_password
    rescue Exception => e
      logger.error(e)
      flash[:error] =  'No se pudo asignar un nuevo password, no se envió ningún correo'
    else
      begin
        NewPasswordMailer.deliver_mail_with_new_password(user,new_passwd)
        
      rescue Exception => e
        logger.error(e)
        flash[:error] =  "No se pudo enviar el correo con el nuevo password, por favor ponte en contacto con un administrator y vuelve a intentarlo"
      else
        flash[:notice] = "Se ha enviado un nuevo password a #{@user.email}"        
      end
    end 
    return render(:action=>'signin')   
  end
  
  def adm
    session[:menupage] = 'admin'
    return redirect_to(:action=>'edit',:controller=>'account') if @current_user.is_account_owner? && !@current_user.is_administrator?   
    redirect_to :action => 'list',:controller=>'users'
  end
  
  def user
    session[:menupage] = 'user'
    return redirect_to(:action=>'index',:controller=>'expenses') if @current_user.is_account_owner?    
    redirect_default(@current_user)
  end
  
  def backoffice
    session[:menupage] = 'backoffice'
    redirect_to :controller=>'enterprises',:action=>'list'   
  end
end
