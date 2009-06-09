require 'digest/sha1'

class User < ActiveRecord::Base
  
  belongs_to :enterprise
  has_one :owned_enterprise, :class_name => 'Enterprise', :foreign_key => 'account_owner_id', :dependent => :nullify

  has_many :expenses
  has_many :revised_expenses, :class_name => 'Expense', :foreign_key => 'revised_by', :dependent => :destroy

  has_many :payments
  has_many :ordered_payments, :class_name => 'Payment', :foreign_key => 'ordered_by', :dependent => :destroy

  has_many :supervised_projects, :class_name => 'Project', :foreign_key => 'supervisor_id', :dependent => :destroy

  belongs_to :supervisor, :class_name => 'User', :foreign_key => 'supervisor_id'
  has_many :supervised_users, :class_name => 'User', :foreign_key => 'supervisor_id'

  add_for_sorting_to :first_name, :last_name
  #Valida que se puede borrar el usuario
  before_destroy :check_destroy
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :first_name,
                            :message => '^Nombre no puede estar vacío'
  validates_length_of       :first_name, :within => 0..255,
                            :too_long => '^Nombre demasiado largo max. %d'

  validates_presence_of     :last_name,
                            :message => '^Apellidos no puede estar vacío'
  validates_length_of       :last_name, :within => 0..255,
                            :too_long => '^Apellidos demasiado largo max. %d'

  validates_presence_of     :password,
                            :if => :password_required?,
                            :message => '^Contraseña no puede estar vacío'
  validates_length_of       :password, :within => 4..40,
                            :if => :password_required?,
                            :too_long => '^Contraseña demasiado larga max. %d',
                            :too_short => '^Contraseña demasiado corta min. %d'
  validates_presence_of     :password_confirmation,
         		            :if => :password_required?,
                            :message => '^Confirmación de contraseña no puede estar vacío'
  validates_confirmation_of :password,
                            :if => :password_required?,
                            :message => '^La Contraseña no coincide con su confirmación'

  validates_presence_of     :email,
                            :message => '^Email no puede estar vacío'
  validates_length_of       :email,    :within => 3..100,
                            :too_long => '^Email demasiado largo max. %d',
                            :too_short => '^Email demasiado corto min. %d'
  validates_uniqueness_of   :email, :case_sensitive => false, :scope => :enterprise_id,
                            :message => '^Lo siento Email repetido, elija otro'
  validates_format_of       :email,
                            :with => /^[A-Z0-9._%-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}$/i,
                            :message => '^Email debe ser una dirección de correo'
                            
  validates_presence_of     :email_confirmation,         		 
                            :on => :create,           
                            :message => '^Confirmación de email no puede estar vacío'                            
  validates_confirmation_of :email,         
                            :on => :create,
                            :message => '^El email no coincide con su confirmación'
                            
  validates_presence_of     :enterprise_id,
                            :message => '^Debe seleccionar una empresa',
                            :if => :not_account_owner_in_signup
  validates_presence_of     :enterprise,
                            :message => '^Empresa inexistente',
                            :if => :enterprise_id

  validates_presence_of     :supervisor_id,
                            :message => '^Debe seleccionar un supervisor',
                            :if => :not_account_owner
  validates_presence_of     :supervisor,
                            :message => '^Supervisor inexistente',
                            :if => :supervisor_id

  before_create :make_activation_code
  before_save :encrypt_password

  @scaffold_columns = [                                                                                                                            
    AjaxScaffold::ScaffoldColumn.new(self,{ :name => "email", :label => 'Email', :sort_sql => 'users.email'}),    
    AjaxScaffold::ScaffoldColumn.new(self,{ :name => "first_name", :label => 'Nombre', :sort_sql => 'users.first_name_for_sorting'}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :name => "last_name", :label => 'Apellidos', :sort_sql => 'users.last_name_for_sorting'}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :title=>'Administrador',:name => "is_administrator", :label => 'A',:eval=>'user.is_administrator? ? image_tag("ico_estado_ok.gif") : "&nbsp;"', :sort_sql => 'users.is_administrator'}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :title=>'Supervisor',:name => "is_supervisor", :label => 'S', :eval=>'user.is_supervisor? ? image_tag("ico_estado_ok.gif") : "&nbsp;"',:sort_sql => 'users.is_supervisor'}),       
    AjaxScaffold::ScaffoldColumn.new(self,{ :title=>'Pagador',:name => "is_payer", :label => 'P',:eval=>'user.is_payer ? image_tag("ico_estado_ok.gif") : "&nbsp;"', :sort_sql => 'users.is_payer'}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :title=>'Gestor',:name => "is_gestor", :label => 'G',:eval=>'user.is_gestor ? image_tag("ico_estado_ok.gif") : "&nbsp;"', :sort_sql => 'users.is_gestor'}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :title=>'Bloqueado',:name => "is_blocked", :label => 'B',:eval=>'user.is_blocked ? image_tag("ico_estado_bloqueado.gif") : "&nbsp;"', :sort_sql => 'users.is_blocked'}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :title=>'Supervisado por',:name => "supervisor_id", :label => 'Supervisor',:eval=>'user.supervisor.print_name',:sort_sql => 'users.supervisor_id'}),
    AjaxScaffold::ScaffoldColumn.new(self,{ :name => "balance", :label => 'Saldo', :eval=>'format_money(user.balance)'})        
  ]
  
  # Assigns a random password and saves.
  def set_new_password    
    new_passwd = generate_password()
    self.password = self.password_confirmation = new_passwd
    self.save!
    return new_passwd
  end

  # Authenticates a user by their email and unencrypted password.  Returns the user or nil.
  def self.authenticate(email, password, enterprise)
    user = enterprise.users.find(
      :first,
      :conditions => ['email = ? and activated_at IS NOT NULL and NOT is_blocked=?', email,true]
    )
    user && user.authenticated?(password) ? user : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  # Activates the user in the database.
  def activate
    @activated = true
    update_attributes(:activated_at => Time.now.utc, :activation_code => nil)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  def balance
    # Note that ''.to_i and nil.to_i give 0.
    total_pending  = expenses.select {|e| e.pending? && e.payment_type != PaymentType::ENTERPRISE_CREDIT_CARD }.inject(0) {|sum, e| sum + e.amount.to_i}
    total_approved = expenses.select {|e| e.approved? && e.payment_type != PaymentType::ENTERPRISE_CREDIT_CARD }.inject(0) {|sum, e| sum + e.amount.to_i}
    total_payments = payments.inject(0) {|sum, p| sum + p.amount.to_i}    
    total_payments - (total_pending + total_approved)
  end

  def is_normal?
    return true unless self.is_administrator? || self.is_supervisor? || self.is_payer?
    nil
  end
    
  def is_account_owner?
    return enterprise && enterprise.account_owner_id == self.id
  end
  
  def is_admin_site?
    return self.is_administrator? && self.enterprise.short_name == 'aspgems'
  end

  def print_name
    first_name + ' ' + last_name
  end
  
  protected
  
  def validate
    if is_account_owner?
      errors.add(:is_administrator, '^El propietario de la cuenta no puede dejar de ser administrador') unless is_administrator?
      errors.add(:is_supervisor, '^El propietario de la cuenta no puede dejar de ser supervisor') unless is_supervisor?
      errors.add(:is_payer, '^El propietario de la cuenta no puede dejar de ser pagador') unless is_payer?
    end
  end
  
  # To prevent validation failure for not having supervisor (account_owner is allowed)
  def not_account_owner
    not_account_owner_in_signup && !is_account_owner? 
  end
  
  # During signup user is validated before saving the enterprise, so it has no enterprise_id
  # To prevent validation failure, we don't validate if enterprise is informed (done in signup_controller)
  def not_account_owner_in_signup
    enterprise.blank? || !enterprise.id.nil?
  end
  
  # before filter 
  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end

  def make_activation_code
    self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  #Genera una password aleatorio
  def generate_password(length = 8)
    chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('1'..'9').to_a - ['o', 'O', 'i', 'I']
    Array.new(length) { chars[rand(chars.size)] }.join
  end
    
  #No se puede borrar el usuario si tiene gastos o pagos asociados.
  #TODO Quizas haya que desactivarlo
  def check_destroy
    raise ActiveRecord::RecordNotSaved.new("No se puede borrar '#{self.print_name}'. Tiene #{expenses.length} gastos asociados") if expenses.length > 0
    raise ActiveRecord::RecordNotSaved.new("No se puede borrar '#{self.print_name}'. Tiene #{payments.length} pagos asociados") if payments.length > 0    
    raise ActiveRecord::RecordNotSaved.new("No se puede borrar '#{self.print_name}'. Es supervisor de #{supervised_users.length} usuarios") if self.is_supervisor? && supervised_users.length > 0    
  end 
end
