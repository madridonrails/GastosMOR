require File.dirname(__FILE__) + '/../test_helper'

class EnterpriseTest < Test::Unit::TestCase

  def test_invalid_with_blank_attributes
    enterprise = Enterprise.new
    assert !enterprise.valid?
    assert enterprise.errors.invalid?(:short_name)
    assert enterprise.errors.invalid?(:name)
    assert enterprise.errors.invalid?(:country_id)
    assert !enterprise.errors.invalid?(:cif)
    assert !enterprise.errors.invalid?(:address)
    assert !enterprise.errors.invalid?(:city)
    assert !enterprise.errors.invalid?(:province)
    assert !enterprise.errors.invalid?(:postal_code)    
  end
  
  def test_invalid_used_short_name
    @short_name = Enterprise.find(:first).short_name
    enterprise = Enterprise.new :name => 'Baz', :country_id => 69, :short_name => @short_name
    assert !enterprise.valid?
    assert enterprise.errors.invalid?(:short_name)
    assert !enterprise.errors.invalid?(:name)
    assert !enterprise.errors.invalid?(:country_id)    
  end
  
  def test_invalid_reserved_short_name
    enterprise = Enterprise.new :name => 'Baz', 
      :country_id => 69, :short_name => GastosgemUtils::RESERVED_SUBDOMAINS[0]
    assert !enterprise.valid?
    assert enterprise.errors.invalid?(:short_name)
    assert !enterprise.errors.invalid?(:name)
    assert !enterprise.errors.invalid?(:country_id)    
  end

  def test_valid_enterprise
    enterprise = Enterprise.new :name => 'Baz', 
      :country_id => 69, :short_name => 'baz'
    assert enterprise.valid?
    assert enterprise.save
  end
end
