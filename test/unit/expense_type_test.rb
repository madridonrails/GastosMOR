require File.dirname(__FILE__) + '/../test_helper'

class ExpenseTypeTest < Test::Unit::TestCase

  def test_invalid_with_blank_attributes
    expense_type = ExpenseType.new
    assert !expense_type.valid?
    assert expense_type.errors.invalid?(:description)
    assert expense_type.errors.invalid?(:enterprise_id)
    assert !expense_type.errors.invalid?(:parent_id)
    assert !expense_type.errors.invalid?(:parent)
  end

  def test_invalid_with_invalid_attributes
    expense_type = ExpenseType.new :description => 'General', :enterprise_id => 10000, :parent_id => 10000
    assert !expense_type.valid?
    assert !expense_type.errors.invalid?(:description)
    assert !expense_type.errors.invalid?(:enterprise_id)
    assert expense_type.errors.invalid?(:enterprise)
    assert !expense_type.errors.invalid?(:parent_id)
    assert expense_type.errors.invalid?(:parent)
  end

  def test_invalid_with_used_description
    @enterprise = Enterprise.find(:first)
    @expense_type = @enterprise.expense_types.find(:first)
    expense_type = ExpenseType.new :description => @expense_type.description , :enterprise => @enterprise
    assert !expense_type.valid?
    assert expense_type.errors.invalid?(:description)
    assert !expense_type.errors.invalid?(:enterprise_id)
    assert !expense_type.errors.invalid?(:enterprise)
    assert !expense_type.errors.invalid?(:parent_id)
    assert !expense_type.errors.invalid?(:parent)
  end

  def test_valid_expense_type
    @enterprise = Enterprise.find(:first)
    expense_type = ExpenseType.new :description => 'Valid type' , :enterprise => @enterprise
    assert expense_type.valid?
    assert expense_type.save
  end

  def test_valid_expense_type_with_parent
    @enterprise = Enterprise.find(:first)
    @expense_type = @enterprise.expense_types.find(:first)
    expense_type = ExpenseType.new :description => 'Valid type' , :enterprise => @enterprise, 
      :parent => @expense_type
    assert expense_type.valid?
    assert expense_type.save
  end

end
