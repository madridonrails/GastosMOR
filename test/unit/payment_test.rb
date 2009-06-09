require File.dirname(__FILE__) + '/../test_helper'

class PaymentTest < Test::Unit::TestCase

  def test_invalid_with_blank_attributes
    payment = Payment.new :amount => nil
    assert !payment.valid?
    assert payment.errors.invalid?(:date)
    assert payment.errors.invalid?(:amount)
    assert payment.errors.invalid?(:concept)
    assert payment.errors.invalid?(:user_id)
    assert payment.errors.invalid?(:ordered_by)
  end

  def test_invalid_with_invalid_attributes
    payment = Payment.new :date => '2007-02-30', :amount => 'a10', :description => 'Invalid Test', 
      :concept => 'Invalid Test', :user_id => 10000, :ordered_by => 20000
    assert !payment.valid?
    assert payment.errors.invalid?(:date)
    assert payment.errors.invalid?(:amount)
    assert !payment.errors.invalid?(:concept)
    assert !payment.errors.invalid?(:user_id)
    assert payment.errors.invalid?(:user)
    assert !payment.errors.invalid?(:ordered_by)
    assert payment.errors.invalid?(:orderer)
  end

  def test_invalid_with_orderer_not_payer
    payment = new_payment
    payment.orderer = User.find(:first, :conditions => ['is_payer = ?', 0])
    assert !payment.valid?
    assert !payment.errors.invalid?(:date)
    assert !payment.errors.invalid?(:amount)
    assert !payment.errors.invalid?(:concept)
    assert !payment.errors.invalid?(:user_id)
    assert !payment.errors.invalid?(:user)
    assert !payment.errors.invalid?(:ordered_by)
    assert payment.errors.invalid?(:orderer)
  end

  def test_valid_payment
    payment = new_payment
    payment.orderer = User.find(:first, :conditions => ['is_payer = ?', 1])
    assert payment.valid?
    assert payment.save
  end

  private

  def new_payment
    @user = User.find(:first)
    payment = Payment.new :date => Date.today, :amount => 100, :description => 'Test',
      :concept => 'Pago', :user => @user
  end
  
end
