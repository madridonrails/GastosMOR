class Payment < ActiveRecord::Base
  belongs_to :user
  belongs_to :orderer, :class_name => 'User', :foreign_key => 'ordered_by'

  add_for_sorting_to :concept
  
  # A payment is not associated with an expense nor with a project, it is just money.
  
  validates_presence_of     :date,
                            :message => '^La fecha no puede estar vacía'

  validates_numericality_of :amount,
                            :only_integer => true,
                            :message => '^Importe incorrecto'

  validates_presence_of     :concept,
                            :message => '^El concepto no puede estar vacío'

  validates_presence_of     :user_id,
                            :message => '^Debe seleccionar un usuario'
  validates_presence_of     :user,
                            :message => '^Usuario inexistente, seleccione uno de la lista',
                            :if => :user_id

  validates_presence_of     :ordered_by,
                            :message => '^Debe seleccionar un pagador'
  validates_presence_of     :orderer,
                            :message => '^Usuario pagador inexistente',
                            :if => :ordered_by

  def validate
    if date
      errors.add(:date, '^La fecha no es válida') unless Date.valid_date? date.year, date.mon, date.day
    end
    if orderer
      errors.add(:orderer, '^El usuario ordenante no es un pagador') unless orderer.is_payer?
    end
  end  

  def amount=(am)
    write_attribute(:amount, GastosgemUtils.format_amount(am)) 
  end

end
