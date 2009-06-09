# This is not an AR model.
class ExpenseStatus
  PENDING  = 'pending'
  APPROVED = 'approved'
  REJECTED = 'rejected'
  
  ALL = [PENDING, APPROVED, REJECTED]
  
  @combo = [['Aprobado' ,ExpenseStatus::APPROVED],
            ['Pendiente',ExpenseStatus::PENDING],
            ['Rechazado',ExpenseStatus::REJECTED]]
     
  def self.combo
    @combo
  end
  
  def self.get_text (value)
    @combo.each { |e|
      return e[0] if e[1] == value
    }
    return ''
  end
end