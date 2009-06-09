class PaymentsController < ApplicationController
  include AjaxScaffold::Controller
  
  before_filter :admin_and_payer_required, :only => [:list_payer]
  before_filter :gestor_required, :only => [:gestor_payer]
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }
  
  def index
    session[:page_payer]= false    
    list    
  end
  
  def gestor_list_payer
    list_payer
  end
  
  def list_payer
    session[:page_payer]= true    
    list    
  end
  
  def list
    @page_payer = session[:page_payer]        
    @user_combo = get_user_list_by_enterprise(@current_user,@enterprise)
    @payment_pages, @payments = paginate :payments, :per_page => GastosgemUtils::PAGE_SIZE
    render :action => 'list'
  end

end
