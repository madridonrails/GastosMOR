class Enterprise < ActiveRecord::Base
  require 'RMagick'

  belongs_to :country
  belongs_to :account_owner, :class_name => 'User', :foreign_key => :account_owner_id
  has_many :users, :dependent => :destroy
  has_many :expense_types, :dependent => :destroy
  has_many :projects, :dependent => :destroy
  
  validates_presence_of     :name,
                            :message => '^Nombre no puede estar vacío'
  validates_length_of       :name, :within => 0..255,
                            :too_long => '^Nombre demasiado largo max. %d'

  validates_presence_of     :short_name,
                            :message => '^Alias no puede estar vacío'
  validates_length_of       :short_name, :within => 0..22,
                            :too_long => '^Alias demasiado largo max. %d'
  validates_uniqueness_of   :short_name, :case_sensitive => false,
                            :message => '^Lo siento Alias repetido, elige otro'
  validates_exclusion_of    :short_name,
                            :in => GastosgemUtils::RESERVED_SUBDOMAINS,
                            :message => '^Lo siento Alias repetido, elige otro'
  validates_format_of       :short_name,
                            :with => /^[a-z][\-a-z0-9]*$/,
                            :message => '^El Alias sólo puede tener caracteres alfanuméricos'                                 
  validates_presence_of     :country_id,
                            :message => '^Debes seleccionar tu país',
                            :on => :create
  validates_presence_of     :country,
                            :message => '^País inexistente, seleccione uno de la lista',
                            :if => :country_id

  @scaffold_columns = [                                                                                                                            
    AjaxScaffold::ScaffoldColumn.new(self,{ :name => 'short_name', :label => 'Nombre', :sort_sql => 'enterprises.short_name'}),    
    AjaxScaffold::ScaffoldColumn.new(self,{ :name => 'name', :label => 'Descripcion', :sort_sql => 'enterprises.name'}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :name => 'is_active', :label => 'Act.', :sort_sql=>'users.activation_code',:eval=>'enterprise.account_owner.activation_code.blank? ? theme_image_tag("ico_estado_ok.gif"):theme_image_tag("ico_estado_no.gif") '}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :name=>'is_blocked',:label => 'Bloq.',:eval=>'enterprise.is_blocked? ? theme_image_tag("ico_estado_ok.gif") : theme_image_tag("ico_estado_no.gif")', :sort_sql => 'enterprises.is_blocked'}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :name => 'user', :label => 'Usuario', :eval => 'enterprise.account_owner.email',:sortable=>false}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :name=>'created_at',:label => 'F. Alta', :eval=>'date_eu(enterprise.created_at)',:sort_sql=>'enterprises.created_at'}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :name=>'users',:label => 'Us.', :eval=>'enterprise.users.length',:sortable => false}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :name=>'projects',:label => 'Pro.', :eval=>'enterprise.projects.length',:sortable => false}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :name=>'expenses',:label => 'Gas.', :eval=>'enterprise.expenses_length',:sortable => false}),
    

  ]
  
  def expenses_length
    count=0
    users.each { |u| count += u.expenses.length}
    count
  end

  def resize_logo
    return nil if self.logo.blank?
    img = Magick::Image.read("public/logos/#{self.logo}").first
    img.change_geometry!('105x175>') do |cols, rows, img| #FYI http://www.imagemagick.org/RMagick/doc/imusage.html#geometry
      img.resize!(cols,rows)
    end
    img.write "public/logos/#{self.logo}" # NOTE - Is it really needed? or exist other method?
  end
  
  #Borra un empresa y todos sus datos asociados.
  def purge
     
    raise ActiveRecord::RecordNotSaved.new("No se puede eleminar la empresa #{short_name}") if short_name == 'aspgems'
    
    ActiveRecord::Base.transaction do
      #Gastos
      ActiveRecord::Base.connection.execute("DELETE FROM expenses WHERE user_id IN ( SELECT id FROM users WHERE enterprise_id = #{id})")
      #Pagos
      ActiveRecord::Base.connection.execute("DELETE FROM payments WHERE user_id IN ( SELECT id FROM users WHERE enterprise_id = #{id})")
      #Proyectos
      ActiveRecord::Base.connection.execute("DELETE from projects WHERE enterprise_id = #{id}")
      #Tipos de gastos
      #Importante el order para borrar los hijos primero
      ActiveRecord::Base.connection.execute("UPDATE expense_types SET parent_id=NULL WHERE enterprise_id=#{id}")
      ActiveRecord::Base.connection.execute("DELETE from expense_types WHERE enterprise_id = #{id} order by parent_id desc")
      #Usuarios
      #Empresa account_owner a null para borrar los usuarios 
      ActiveRecord::Base.connection.execute("UPDATE enterprises SET account_owner_id=NULL WHERE id=#{id}")
      #Importante el order para borrar los que tienen supervisor primero
      ActiveRecord::Base.connection.execute("UPDATE users SET supervisor_id=NULL WHERE enterprise_id = #{id}")
      ActiveRecord::Base.connection.execute("DELETE FROM users WHERE enterprise_id = #{id} ORDER BY is_supervisor DESC")      
      #Empresa
      ActiveRecord::Base.connection.execute("DELETE FROM enterprises WHERE id = #{id}");
      return true
    end
    
  end
  
  protected

  # short_name downcase
  def before_validation
    unless cif.blank?
      cif.upcase!
      cif.gsub!(/\W/,'')
    end
  end

  # default values are set before saving
  def before_save
    short_name.downcase!
    self.theme = 'default' if theme.blank?
    self.cif ||= ''
    resize_logo
  end

  def before_destroy
    self.account_owner_id = nil
    save
  end

  def is_bank_account_valid?
    candidate = bank_account.dup

    # Validation algorithm taken from:
    # http://www.euskalgraffiti.com/index.php/archives/2005/02/08/calculo-del-digito-de-control-de-una-cuenta-corriente/
  
    # we convert the string to an array of integer
    digits = str_to_int_array(candidate)
    
    entity_office = digits[0,8]
    control = digits[8,2]
    account = digits[10,10]
  
    weights = [1,2,4,8,5,10,9,7,3,6]

    test_control = [0,0]
    (0..7).each { |pos| test_control[0] += entity_office[pos] * weights[pos+2] }
    (0..9).each { |pos| test_control[1] += account[pos] * weights[pos] }

    test_control.collect! do |c|
      c = 11 - (c % 11)
      c = 0 if c == 11
      c = 1 if c == 10
      c
    end
    
    control == test_control
  end

  def add_digits_from_int(n)
    digits = str_to_int_array(n.to_s)
    digits.inject(0) { |acum, n| acum + n }
  end

  def str_to_int_array(str)
    (0..(str.length-1)).inject([]) { |result, pos| result << str[pos,1].to_i }
  end

  def validate_cif
    errors.add(:cif, '^El CIF no es válido') unless is_cif_valid?
  end
  
  def is_cif_valid?
    candidate = cif.dup

    # We also accept NIFs, NIF validation algoritm taken from:
    # http://es.wikipedia.org/wiki/Algoritmo_para_obtener_la_letra_del_NIF
    if candidate.match(/(\d{8})\D/)
      nif_letter = candidate[-1, 1]
      nif_digits = candidate[0,8]
    elsif candidate.match(/X(\d{7})\D/)
      nif_letter = candidate[-1, 1]
      nif_digits = candidate[1,7]
    end
    nif_addition = nif_digits.to_i % 23
    return true if nif_letter && nif_digits && 'TRWAGMYFPDXBNJZSQVHLCKE'[nif_addition,1] == nif_letter
    
    # CIF validation algorithm taken from:
    # http://club.telepolis.com/jagar1/Ccif.htm
    return false unless "ABCDEFGHKLMNPQS".include? candidate[0,1]
    central_digits = str_to_int_array(candidate[1,7])
    
    a = [1,3,5].inject(0) { |acum, pos| central_digits[pos] + acum }    
    b = [0,2,4,6].inject(0) { |acum, pos| acum + add_digits_from_int(central_digits[pos] * 2) }

    candidate_digit = 10 - ( (a+b) % 10)
    candidate_letter = "JABCDEFGHI"[candidate_digit,1]
    
    control_digit = candidate[8,1]

    return control_digit == candidate_digit.to_s if 'ABEH'.include? candidate[0,1]
    return control_digit == candidate_letter if 'KLMPQS'.include? candidate[0,1]
    return control_digit == candidate_digit.to_s || control_digit == candidate_letter if 'CDFGN'.include? candidate[0,1]
  end
  
end
