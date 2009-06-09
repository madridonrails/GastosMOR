module PublicHelper
  def ir_al_principio
    link_to 'Ir al principio'
  end
    
  def help_answer_separator
    '<div class="help-answer-separator"></div>'
  end
  
  def date_una_vuelta_o_registrate
    registrate_gratis
  end

  def registrate_gratis
    return <<-HTML
    <div class="TextHighlightOrange" style="width: 30%; margin-left: auto; margin-right: auto; margin-top: 30px">
      #{link_to 'Regístrate gratis', :action => 'signup'}
  	</div>
    HTML
  end
end
