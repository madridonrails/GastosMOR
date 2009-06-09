# This is not an AR model.
class PaymentType
  CASH = 0  
  ENTERPRISE_CREDIT_CARD = 1
  
  ALL = [CASH, ENTERPRISE_CREDIT_CARD]
    
  @combo = [['Efectivo', PaymentType::CASH],
            ['Tarjeta de empresa', ENTERPRISE_CREDIT_CARD]]
     
  def self.combo
    @combo
  end
  
  def self.find_by_name(name)
    @combo.each do |row| 
      return row[1] if row[0] == name
    end
    return nil
  end

  def self.find_by_id(id)
    @combo.each do |row| 
      return row[0] if row[1] == id
    end
    return nil
  end

end
