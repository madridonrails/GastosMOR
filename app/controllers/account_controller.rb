class AccountController < ApplicationController
  include AjaxScaffold::Controller
  include AccountLocation

  before_filter :account_owner_required        
     
  def edit    
    render :action=>"edit",:layout=>"application"
  end
  
  def save_account
    return edit if !params[:clear].blank?
    @successful = true
    flash[:error]=''
    begin             
      image = params['file_logo']           
      str_logo = "logo_#{@enterprise.short_name}.gif"                                                         
      if !image.blank? && image.size > 0        
        if  (image.size/1000) > GastosgemUtils::LOGO_MAX_SIZE           
          flash[:error], @successful  = "Tamaño del logo demasiado grande, el maximo es de #{GastosgemUtils::LOGO_MAX_SIZE} Kb", false
        else                   
         logger.debug("guardando fichero #{image.content_type}/#{image.original_filename}/")       
         File.open("public/logos/#{str_logo}", "wb") { |f| f.write(image.read) }
         params[:enterprise]['logo']= str_logo         
        end
      end
      
      @successful = @enterprise.update_attributes(params[:enterprise]) if @successful

      #we can do resize the logo inline[http://www.imagemagick.org/RMagick/doc/image1.html#read_inline]
      #@enterprise.resize_logo if @successful

    rescue ActiveRecord::RecordInvalid => invalid
       @successful  =  false
    rescue
      flash[:error], @successful  = $!.to_s, false
    end
    render :action=>"edit",:layout=>"application"
  end
end
