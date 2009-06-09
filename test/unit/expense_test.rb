require File.dirname(__FILE__) + '/../test_helper'

class ExpenseTest < Test::Unit::TestCase

  def test_invalid_with_blank_attributes
    expense = Expense.new :payment_type => nil
    assert !expense.valid?
    assert expense.errors.invalid?(:date)
    assert expense.errors.invalid?(:amount)
    assert expense.errors.invalid?(:description)
    assert expense.errors.invalid?(:status)
    assert expense.errors.invalid?(:project_id)
    assert expense.errors.invalid?(:expense_type_id)
    assert expense.errors.invalid?(:payment_type)
    assert expense.errors.invalid?(:user_id)
  end

  def test_invalid_with_invalid_attributes
    expense = Expense.new :date => '2007-02-30', :amount => 'a10', :description => 'Invalid Test', 
      :status => 'error', :project_id => 10000, :expense_type_id => 10000, 
      :payment_type => 1000, :user_id => 10000
    assert !expense.valid?
    assert expense.errors.invalid?(:date)
    assert expense.errors.invalid?(:amount)
    assert !expense.errors.invalid?(:description)
    assert expense.errors.invalid?(:status)
    assert !expense.errors.invalid?(:project_id)
    assert expense.errors.invalid?(:project)
    assert !expense.errors.invalid?(:expense_type_id)
    assert expense.errors.invalid?(:expense_type)
    assert expense.errors.invalid?(:payment_type)
    assert !expense.errors.invalid?(:user_id)
    assert expense.errors.invalid?(:user)
  end

  def test_valid_expense
    expense = new_expense
    assert expense.valid?
    assert expense.save
  end

  def test_valid_expense_with_invalid_reviser
    expense = new_expense
    expense.save
    expense.revised_by = 10000
    assert !expense.valid?
    assert !expense.errors.invalid?(:revised_by)
    assert expense.errors.invalid?(:reviser)
  end

  def test_valid_expense_with_valid_reviser
    expense = new_expense
    expense.save
    expense.revised_by = @user
    assert expense.valid?
    assert expense.save
  end

  private

  def new_expense
    @user = User.find(:first)
    @project = @user.enterprise.projects.find(:first)
    @expense_type = @user.enterprise.expense_types.find(:first)
    expense = Expense.new :date => Date.today, :amount => 100, :description => 'Test',
      :status => ExpenseStatus::PENDING, :project => @project, :expense_type => @expense_type, 
      :payment_type => PaymentType::CASH, :user => @user
  end
  
end
