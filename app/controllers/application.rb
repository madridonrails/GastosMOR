# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base 
  include ExceptionNotifiable 
  include AuthenticatedSystem
  include AccountLocation
  
  before_filter :find_enterprise
  before_filter :redirect_if_www
  before_filter :check_authentication, :except => [ :rescue_404 ]
  before_filter :filter_params

  filter_parameter_logging :password

  after_filter :set_charset

  # before_filter :set_locale
   
  #Theme support
  theme :get_theme
  
  #Mantenimiento de historico para botones back de la ayuda.
  DEFAULT_URL = '/public/index'
  history :default => DEFAULT_URL, :max => 5

  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_gastosgem_mor_session_id'

  # Catch wrong urls and redirect to index
  def rescue_404
    redirect_to :controller => 'public', :action => 'index'
  end

  #obtener el tema de la BD
  def get_theme          
     return (@enterprise ? @enterprise.theme : "default")
  end
  
  #Resetear los valores de los filtros de la sesion
  def reset_filter_params
    session[:filter]=nil
  end
  
  protected
  
  #Guarda en la sesion los parametros de los filtros. Es necesario tenerlos guardados en la sesion
  #para cuando se esta paginando no perder los datos del filtro.
  #Sera necesario 'resetearlos' cuando se entre a las páginas que tengan paginación por primera
  #vez para que no se mezclen los datos de otras paginacions (método reset_filter_params)
  def filter_params
    #inicializar variable
    session[:filter] ||= {}
    #guardar parametros en sesion
    params.each { |key,value|
      if (key.instance_of?(String) && key.index('crt_') == 0) || (value.to_a.join(',').index('crt_') != nil )
        session[:filter][key] = value       
      end      
    }

    #Meter parametros de session en el array params
    session[:filter].each { |key,value|
      params[key]=value 
    }
    
    params[:page] = '1' if params[:page].blank?
  end
  
  def check_authentication
    session[:intended_action] = action_name
    session[:intended_controller] = controller_name
    unless session[:user]
      flash[:notice]='Usuario y password requerido'
      redirect_to :action => 'signin', :controller => 'admin'
      return false
    end
    begin
      @current_user = User.find_by_id(session[:user],:conditions=>['enterprise_id=?',@enterprise.id])
    rescue Exception => e
      session[:user] = nil
      @errors = 'Sesion de usuario incorrecta'
      logger.error(e)
      redirect_to(:action => 'signin', :controller => 'admin')
      return false
    end
  end

  def admin_required
    return false if @current_user.nil?
    redirect_default(@current_user) unless @current_user.is_administrator?
    return @current_user.is_administrator?
  end

  def supervisor_required
    return false if @current_user.nil?
    redirect_default(@current_user) unless @current_user.is_supervisor?
    return @current_user.is_supervisor?
  end
  
  def payer_required
    return false if @current_user.nil?
    redirect_default(@current_user) unless @current_user.is_payer?
    return @current_user.is_payer?
  end
  
  def admin_and_payer_required
    return false if @current_user.nil?
    redirect_default(@current_user) unless @current_user.is_administrator? || @current_user.is_payer?
    return @current_user.is_administrator? || @current_user.is_payer?
  end
 
  def supervisor_or_gestor_required
    return false if @current_user.nil?
    redirect_default(@current_user) unless @current_user.is_supervisor? || @current_user.is_gestor?
    return @current_user.is_supervisor? || @current_user.is_gestor?
  end
 
  def account_owner_required   
    return false if @current_user.nil?
    redirect_default(@current_user) unless @current_user.is_account_owner?
    return @current_user.is_account_owner?
  end 
  
  def admin_site_required   
    return false if @current_user.nil?
    redirect_default(@current_user) unless @current_user.is_admin_site?
    return @current_user.is_admin_site?
  end 
  
  def gestor_required
    return false if @current_user.nil?
    redirect_default(@current_user) unless @current_user.is_gestor?
    return @current_user.is_gestor?
  end

  def paginate_collection(collection, options = {})
    default_options = {:per_page => 10, :page => 1}
    options = default_options.merge options
    
    pages = Paginator.new self, collection.size, options[:per_page], options[:page]
    first = pages.current.offset
    last = [first + options[:per_page], collection.size].min
    slice = collection[first...last]
    return [pages, slice]
  end
    
  public
  
  def set_locale
    if !params[:locale].nil? && LOCALES.keys.include?(params[:locale])
      Locale.set LOCALES[params[:locale]]
    else
      redirect_to params.merge( 'locale' => Locale.base_language.code )
    end
  end
  
  def redirect_back_or_default(user)
    if session[:intended_controller] && session[:intended_controller]!='admin'
      redirect_back_
    else
      redirect_default(user)
    end
  end
  
  def redirect_back_
    redirect_to :action => session[:intended_action], :controller => session[:intended_controller]
    session[:intended_action]=nil
    session[:intended_controller]=nil
  end
  
  def redirect_default(user)
    if user.is_account_owner? # Propietario de la cuenta
      redirect_to :controller => 'expenses', :action => 'index'
#      redirect_to :controller => 'admin', :action=>'adm'
    elsif user.is_administrator? # Administrador
      redirect_to :controller => 'expenses', :action => 'index'
    elsif user.is_supervisor? # Supervisor
      redirect_to :controller => 'expenses', :action => 'list_pending'
    elsif user.is_payer?      # Pagador
      redirect_to :controller => 'payments', :action => 'index'
    elsif user.is_gestor?     # Gestor
      redirect_to :controller => 'export', :action=> 'index'
    else                      # Usuario normal
      redirect_to :controller => 'expenses', :action => 'index'
    end         
  end
  
  def back
   redirect_back(2)
  end
  
  #Combo de usuarios
  def get_user_list_by_enterprise(user,enterprise)   
    if user.is_administrator? || user.is_gestor? || user.is_payer?
      User.find(:all,:conditions=>['enterprise_id=?',enterprise.id]).collect {|p| [p.first_name+' '+p.last_name, p.id ] }
    else user.is_supervisor?
      user.supervised_users.collect {|p| [p.first_name+' '+p.last_name, p.id ] }          
    end
  end
  
  protected
  
  # The chosen content type is the one recommended
  # here[http://www.hixie.ch/advocacy/xhtml].
  def set_charset
    headers['Content-Type'] ||= 'text/html; charset=UTF-8'
  end
  
  # Robust computation of +order_by+ for column ordering in tables. This
  # method checks +params+ for a <tt>:order_by</tt> key and tries to use
  # that as default value.
  def order_by(ncols, default=0)
    if params[:order_by].nil?
      order_by = default
    else
      begin
        order_by = params[:order_by].to_i
        unless 0 <= order_by && order_by < ncols
          order_by = default
        end
      rescue Exception => e
        logger.error(e)
        order_by = default
      end
    end
    order_by
  end
  
  # Robust computation of +direction+ for column ordering in tables.
  # This method checks +params+ for a <tt>:direction</tt> key and tries
  # to use that as default value.
  def direction(default='ASC')
    if params[:direction].nil?
      direction = default
    else
      direction = params[:direction]
      direction = default unless ['ASC', 'DESC'].include?(direction)
    end
    direction
  end
  
  # Ajax actions that find some problem need to do a redirect, but +redirect_to+
  # does not work well because we are being called from JavaScript and is the
  # result of the redirection what will end up in the original view, the main
  # page is still there. To get a regular redirection we need to send back a
  # litte JavaScript. In modern Rails this would be probably cleaner using RJS.
  def javascript_redirect_to(options={}, *parameters_for_method_reference)
    url = url_for(options, *parameters_for_method_reference)
    render :text => %Q{<script type="javascript">window.location="#{url}"</script>}
  end
  
  def find_enterprise
    if account_subdomain.blank?
      wrong_subdomain
      return false
    end
    
    as = account_subdomain
    if GastosgemUtils::RESERVED_SUBDOMAINS.include?(as)
      @enterprise = nil
      return
    else
      @enterprise = Enterprise.find_by_short_name(as) rescue nil
      if @enterprise.nil?
        wrong_subdomain
        return false
      end
    end
  end

  def default_account_subdomain
    @enterprise.short_name rescue 'www'
  end

  def redirect_if_www
    if account_subdomain == 'www'
      redirect_to(:controller => 'public', :action => 'index')
      return false
    end
  end
  
  private

  def wrong_subdomain
    # If url don't have subdomain write www. prefix
    #newhost = request.subdomains.blank? ? "www.#{request.host}" : request.host.gsub(request.subdomains.join('.'), 'www')
    #newhost += request.port == request.standard_port ? '' : ":#{request.port}" 
    #redirect_to :controller => 'public', :action => 'index', :host => newhost
    redirect_to_url "http://www.#{account_domain}#{request.request_uri}"
  end

end
