# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

# Sometimes the same image is used more than once in the same page.
  # Since we need an id to implement the rollover effect we append a
  # counter, not very elegant, but it works and is simple.
  @@image_id_suffix = 0
  
  # We accept up to this repetitions of the same image in the same page.
  # The purpose of this maximum is to keep the counter in control even
  # if the application runs for months non-stop. There's no need to
  # switch to bignums.
  @@max_image_id_suffix = 1024
  
  def display_user(user)
    "#{user.first_name} #{user.last_name}"
  end

  def display_user_by_id(user)
  return nil if user.blank?
    user = User.find(user)
    "#{user.first_name} #{user.last_name}"
  end

  # We store money as integers to be able to do exact additions and
  # subtractions. When we render those quantities back, we deal with
  # integers as strings as much as possible to avoid floating-point
  # gotchas. We finally delegate to number_to_currency.
  def format_money(number, pos=2, unit='', separator=',', delimiter='.')
    return number if number.nil? # this is what number_to_currency returns on nil
    number = number.to_i
    n = if number.abs < 10**pos
      width = number < 0 ? pos+2 : pos+1
      sprintf("%0#{width}d", number)
    else
      number.to_s
    end
    n.sub!(/(\d+)(\d{#{pos}})$/, "\\1\.\\2")        
    number_to_currency(n, {
      :unit      => unit,
      :separator => separator,
      :delimiter => delimiter
    })
  end

  # Returns the links to pages for paginated listings.
  def pagination_links_remote(options={})
    paginator = options[:paginator]
    actions = []
    1.upto(paginator.page_count) do |n|
      if paginator[n] == paginator.current_page
        actions << n.to_s
      else
        options[:url][:page] = n
        actions << link_to_remote(n.to_s, options)
      end
    end
    "[ #{actions.join(' | ')} ]"
  end

  # Returns the link to the next page for paginated listings.
  def pagination_link_next(str,options={})
    paginator = options[:paginator]
    puts "next: #{paginator}"
    actions = []
    unless paginator.current.next.nil?
        options[:url][:page] = paginator.current.next
        actions << link_to_remote(str, options)
    end
    "#{actions}"
  end

  # Returns the link to the previous page for paginated listings.
  def pagination_link_previous(str,options={})
    paginator = options[:paginator]
    actions = []
    unless paginator.current.previous.nil?
        options[:url][:page] = paginator.current.previous
        actions << link_to_remote(str, options)
    end
    "#{actions}"
  end

  # Returns the link to the first page for paginated listings.
  def pagination_link_first(str,options={})
    paginator = options[:paginator]
    actions = []
    unless paginator.current == paginator.first
        options[:url][:page] = paginator.first
        actions << link_to_remote(str, options)
    end
    "#{actions}"
  end

  # Returns the link to the previous page for paginated listings.
  def pagination_link_last(str,options={})
    paginator = options[:paginator]
    actions = []
    unless paginator.current == paginator.last
        options[:url][:page] = paginator.last
        actions << link_to_remote(str, options)
    end
    "#{actions}"
  end

  # Returns the text with the number of pages to paginate.
  def pagination_pages(options={})
    paginator = options[:paginator]    
    "P&aacute;gina #{paginator.current.number} de #{paginator.page_count}"
  end

  # Renders the header of tables for listings, taking into account order and direction.
  # Expects <tt>:labels</tt>, <tt>:update</tt>, <tt>:action</tt>, <tt>:current_page</tt>,
  # <tt>:current_order_by</tt>, <tt>:current_direction</tt>.
  def table_header_remote(args)
    html = '<tr>'
    url = {
      :action => args[:action],
      :page   => args[:current_page]
    }
    args[:labels].each_with_index do |label, c|
      html << '<th >'
      url[:order_by] = c
      arrow = args[:current_direction] == 'ASC' ? 'ico_arrow_up.gif' : 'ico_arrow_down.gif'
      if c == args[:current_order_by]
        arrow = arrow[0..-5] + '_selected' + arrow[-4..-1]
        icon = "#{image_tag(arrow, {:hspace => '3', :border => '0', :align => 'absmiddle'})}"
        url[:direction] = (args[:current_direction] == 'ASC' ? 'DESC' : 'ASC')
      else
        icon = "#{image_tag(arrow, {:hspace => '3', :border => '0', :align => 'absmiddle'})}"
        url[:direction] = args[:current_direction]
      end
      html << label +
        link_to_remote(
          icon,
          :update => args[:update],
          :url    => url
        )
      html << '</th>'
    end
    html << '</tr>'
    html
  end
  
  # Returns an image linked passing +options+  and +html_options+ to +link_to+.
  # Additionally, sets the +class+ of the link to +img+, adds some JavaScript
  # for image rollover, and assigns an +id+ to it.
  #
  # If the name of the image is <i>foo.png</i> we do not use, nor assume that
  # name actually exists on disk. The method assumes <i>foo_off.png</i> and
  # <i>foo_on.png</i> do exist, those are the images used for the effect.
  def linked_image(image, options={}, html_options={})
    @@image_id_suffix = (@@image_id_suffix + 1) % @@max_image_id_suffix
    ext  = File.extname(image)
    name = File.basename(image, ext)
    off  = name + '_off' + ext 
    on   = name + '_on'  + ext
    id   = sprintf "#{name}_img_%04d", @@image_id_suffix
    link_to(image_tag(off, :id => id), 
            options, 
            html_options.merge(
              :class => 'img',
              :onmouseover => "$('#{id}').src = '#{image_path(on)}'",
              :onmouseout  => "$('#{id}').src = '#{image_path(off)}'"))
  end

  # This is a method analogous to +linked_image+, only it is based on
  # +link_to_remote+.
  def linked_image_remote(image, options={}, html_options={})
    @@image_id_suffix = (@@image_id_suffix + 1) % @@max_image_id_suffix
    ext  = File.extname(image)
    name = File.basename(image, ext)
    off  = name + '_off' + ext 
    on   = name + '_on'  + ext
    id   = sprintf "#{name}_#{ext[1..-1]}_%04d", @@image_id_suffix
    link_to_remote(image_tag(off, :id => id), 
            options,
            html_options.clone.merge(
              :class => 'img',
              :onmouseover => "$('#{id}').src = '#{image_path(on)}'",
              :onmouseout  => "$('#{id}').src = '#{image_path(off)}'"))
  end

  def supervisor_combo(enterprise)
    enterprise.users.find_all_by_is_supervisor(true).map do |user|
      [display_user(user), user.id]
    end
  end
  
  # Returns an array of pairs [expense type, expense_type id] ready to be
  # used in combos.
  def expense_type_combo(enterprise, excluded_id = nil)
    enterprise.expense_types.find(:all, :order => "description",
                     :conditions => excluded_id ? [" expense_types.id <> ? ", excluded_id] : [" 1 = 1"] ).map do |e|
      [e.description, e.id]
    end   
  end

  # Returns an array of pairs [expense type, expense_type id] ready to be
  # used in combos.
  def payment_type_combo(enterprise, excluded_id = nil)   
    PaymentType.combo     
  end
  # Returns an array of pairs [user name, user id] ready to be
  # used in combos.
  def user_combo(enterprise)
    enterprise.users.find(:all, :order => "first_name" ).map do |u|
      [u.first_name+' '+u.last_name, u.id]
    end
  end
  
  # Returns an array of pairs [project type, project id] ready to be
  # used in combos.
  def project_combo(enterprise)
    enterprise.projects.find(:all, :order => "description" ).map do |p|
      [p.name, p.id]
    end
  end
  
  # Returns an array of pairs [plan name, plan id] ready to be
  # used in combos.
  def sino_combo()
      [["Si",1],["No",0]]    
  end
  def countries    
    Country.find(:all, :order => "name" ).map do |p|
      [p.name, p.id]
    end
  end
  

  # Returns a date in eurpean format (dd/mm/yy)
  def date_eu(value)
    value.strftime("%d/%m/%Y")
  end
  
  #TODO - Replace status_image for status_image_str
  # Parameter is a string and return image
  def status_image_str(expense=nil)    
    if expense == ExpenseStatus::PENDING
      image_tag "ico_estado_pendiente.gif", :alt => 'Pendiente de revision', :title => 'Pendiente'
    elsif expense == ExpenseStatus::APPROVED
      image_tag "ico_estado_ok.gif", :alt => 'Aprobado', :title => 'Aprobado'
    elsif expense == ExpenseStatus::REJECTED
      image_tag "ico_estado_no.gif", :alt => 'Denegado', :title => 'Rechazado'
    end
  end

  # Parameter is a expense object and return image
  def status_image(expense)
    if expense.pending?
      image_tag "qm.gif", :alt => 'Pendiente de revision', :title => 'Pendiente'
    elsif expense.approved?
      image_tag "ok.gif", :alt => 'Aprobado', :title => 'Aprobado'
    elsif expense.rejected?
      image_tag "ko.gif", :alt => 'Denegado', :title => 'Rechazado'      
    end
  end
  
  # If +flash+ has <tt>notice</tt>'s or <tt>error</tt>'s keys returns an according +div+ box.
  # Otherwise it returns the empty string, so you can call this method unconditionally
  # from views.
  def display_flash
    display_flash_error + display_flash_notice
  end
  
  # If +flash+ has a key <tt>:notice</tt> returns a +div+ box with its value.
  # Otherwise it returns the empty string, so you can call this method unconditionally
  # from views.
  def display_flash_notice
  logger.debug("FLASH NOTICE [#{flash[:notice]}]")
  %Q{<div class='bannernotice'><span class='notice-message'>#{flash[:notice]}</span></div>} unless flash[:notice].blank?

  end
  
  # If +flash+ has a key <tt>:error</tt> returns a +div+ box with its value.
  # Otherwise it returns the empty string, so you can call this method unconditionally
  # from views.
  def display_flash_error
  logger.debug("FLASH ERROR [#{flash[:error]}]")
   %Q{<div class='bannererror'><span class='error-message'>#{flash[:error]}</span></div>}  unless flash[:error].blank?

  end

  # This helper receives either a model name or an array with error messages
  # and returns a +div+ box with them or the empty string.
  def display_errors(object_name_or_errors_array_or_error_string)
    return '' if object_name_or_errors_array_or_error_string.nil?
    if object_name_or_errors_array_or_error_string.is_a? Array
      errors = object_name_or_errors_array_or_error_string
    elsif object_name_or_errors_array_or_error_string.is_a? String
      errors = [object_name_or_errors_array_or_error_string]
    else
      object = instance_variable_get("@#{object_name_or_errors_array_or_error_string}")
      return '' if object.nil?
      errors = object.errors.full_messages
    end
    return '' if errors.size == 0
    errors_div(errors)
  end

  # Helper method for table row class alternation
  #
  # Usage: In your view call < %= row_class -%> somewhere within your TR tag.
  def row_class(col = '', alt = false)
    @classes = ['filaimpar', 'filapar']
    @alternator || reset_alt
    @alternator += 1 if alt
    @base_class = (@alternator % 2 == 1) ? @classes[0] : @classes[1]
    @base_class += col unless col == ''
    @base_class
  end

  # Call < % reset_alt -%> before the first row of your table to
  # ensure that all tables start with the same color row.
  def reset_alt
    @alternator = 0
  end


  private
  def errors_div(errors)
    if errors.size == 1
      content_tag('div', "<p>#{errors[0]}</p>", :class => 'errors')
    else
      content_tag("div",
        content_tag('ul', errors.map { |m| content_tag('li', m) }),
        "class" => "errors"
      )
    end
  end
  
  #TODO: controlar numero de errores y nombre de la clase
  private
  def error_messages_for_scaffold(object_name, options = {})
    options = options.symbolize_keys
    object = instance_variable_get("@#{object_name}")
    if object && !object.errors.empty?
      content_tag("div",
        content_tag(
          options[:header_tag] || "h2",
          "#{pluralize(object.errors.count, "error")} guardando la informaci&oacute;n"
        ) +
        content_tag("p", "Los siguientes campos contienen errores:<br/><br/>") +
        content_tag("ul", object.errors.full_messages.collect { |msg| content_tag("li", msg) }),
        "id" => options[:id] || "errorExplanation", "class" => options[:class] || "errorExplanation"
      )
    else
      ""
    end
  end

  # ---
  #  
  # Prototype Window Class
  #
  # ---
  def params_for_javascript(params) #options_for_javascript doesn't works fine
    '{' + params.map {|k, v| "#{k}: #{ 
        case v
          when Hash then params_for_javascript( v )
          when String then "'#{v}'"          
        else v   #Isn't neither Hash or String
        end }"}.sort.join(', ') + '}'
  end

  def link_to_prototype_dialog(name, content, dialog_kind = 'alert', options = { :windowParameters => {} }, html_options = {} )
    js_code ="Dialog.#{dialog_kind}( '#{content}',  #{params_for_javascript(options) } ); "
    content_tag(
      "a", 
      name, 
      html_options.merge({ 
        :href => html_options[:href] || "#", 
        :onclick => (html_options[:onclick] ? "#{html_options[:onclick]}; " : "") + js_code
      }))
  end
  
  def link_to_prototype_window(name, window_id, options = { :windowParameters => {} }, html_options = {} )
    js_code ="var win = new Window( '#{window_id}', #{params_for_javascript(options) } ); win.show(); win.setDestroyOnClose();"
      content_tag(
        "a", name, 
        html_options.merge({
          :href => html_options[:href] || "#", 
          :onclick => (html_options[:onclick] ? "#{html_options[:onclick]}; " : "") + js_code
        }))
  end
  
  def txt_scaffold_action (action)
     txt_aceptar = "Aceptar"
     txt_aceptar = "Crear" if action=="create"
     txt_aceptar = "Actualizar" if action=="update"
     return txt_aceptar     
  end
  
  # The application logo as an image tag.
  def application_logo
    image_tag 'logo.png', :alt => "#{APP_NAME}: servicio on-line para la gestión de gastos", :title => "#{APP_NAME}: servicio on-line para la gestión de gastos"
  end

  # Returns the logo of the application already linked to the (public) home.
  def application_logo_linked_to_home
    link_to application_logo, '/'
  end

  #tag para el logo en funcion del tema.
  def logo_image_tag(options={})    
    str_logo = @enterprise && !@enterprise.logo.blank? ? @enterprise.logo : "logo_default.gif"    
    return image_tag("/images/#{str_logo}",options)
  end
  
  #Formulario para upload de ficheros
  def form_remote_upload_tag (options = {})
     options[:html] ||= {}
     options[:html][:id] = options[:html][:id] || 'remote_upload_form' #this needs to generate a unique ID
     options[:html][:target] = 'iframe-remote-upload-' + options[:html][:target] || 'iframe_remote_upload' 
     options[:html][:action] = options[:html][:action] || url_for(options[:url])
     options[:html][:action] += "&amp;remote_upload_id=#{options[:html][:target]}" 
      
     tag('form', options[:html], true)
    
  end
  
  #Cierre del tag del formulario para upload de ficheros
  def end_form_remote_upload_tag (id)
    iframeid = 'iframe-remote-upload-' + id
    "<iframe id='#{iframeid}' name='#{iframeid}' style='height: 0pt; width: 0pt;' frameborder='0'></iframe></form>"
  end
  
  
  private
  def error_messages (errors)
    logger.debug("errores #{errors.to_s}")
    if !errors.blank?             
        errors.full_messages.collect { |msg| content_tag("div","<span class='error-message'>#{msg}</span>","class"=>"bannernotice") }                      
    else
      ""
    end
  end 
end
