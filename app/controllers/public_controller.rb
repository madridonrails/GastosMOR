class PublicController < ApplicationController

  skip_before_filter :check_authentication
  skip_before_filter :redirect_if_www
  before_filter :redirect_unless_www, :except=>[:terms, :back, :contact, :index, :home, :help]
  
  def index
    redirect_to(:action => 'home')
  end

  def home        
  end

  def testimonials
  end

  def faq
  end

  def terms
  end

  def security
  end

  def signup
    redirect_to(:controller=>'signup',:action=>'create_new_user')
  end

  def contact
  end
  
  def terms
  end

  def help
    @current_section = GastosgemUtils.normalize(params[:section])
    file = action_name
    file += "/#{@current_section}" unless @current_section.blank?
    render :controller => :public, :action => file, :layout => true unless @current_section.blank? #rescue nil #don't show error if template not exists
  end

  def redirect_unless_www
    if @enterprise
      if logged_in?
        redirect_default(@current_user)
      else
        redirect_to(:controller => 'admin', :action => 'signin')
      end
      return false
    end
  end
  
  # Renders the form that asks for an email to send a list of valid subdomains
  # and the short_name to redirect to the login page, 
  # if responding to GET. Redirects to the login page on POST.
  # We validate the received short_name corresponds to some enterprise in the
  # database.
  def login
    return unless request.post?
    short_name = params[:short_name]
    if short_name.blank?
      flash.now[:error] = 'Por favor facilita un alias de empresa'
      return
    end
    
    enterprise = Enterprise.find_by_short_name(short_name)
    if not enterprise
      flash.now[:error] = "No hay ninguna empresa con alias #{short_name}"
      return
    end

    newhost = request.host.gsub('www', short_name)
    newhost += request.port == request.standard_port ? '' : ":#{request.port}" 
    redirect_to :controller => 'admin', :action => 'signin', :host => newhost
  end
  
  # Sends the email with a list of valid subdomains.
  # We validate the received email corresponds to some user in the
  # database, and we check for mailer exceptions.
  def subdomains
    redirect_to :action => 'login' and return unless request.post?
    email = params[:email]
    if email.blank?
      flash[:error] = 'Por favor facilita un email'
      redirect_to :action => 'login' and return
    end

    if not email =~ /^[A-Z0-9._%-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$/i
      flash[:error] = "Por favor introduce un email válido"
      redirect_to :action => 'login' and return
    end

    users = User.find_all_by_email(email)
    if users.blank?
      flash[:error] = "No hay ningún usuario con email #{email}"
      redirect_to :action => 'login' and return
    end

    begin
      SubdomainsMailer.deliver_mail_with_subdomains(users)
    rescue Exception => e
      logger.error(e)
      flash[:error] = "No se pudo enviar el correo con la direcci&oacute;n de acceso, por favor ponte en contacto con un administrator y vuelve a intentarlo"
    else
      flash[:notice] = "Se ha enviado la direcci&oacute;n de acceso a #{email}"
    end
    redirect_to :action => 'login'
  end
  
  #To check Exception Notifier
  def error  
    raise RuntimeError, "Generating an error"  
  end

end
