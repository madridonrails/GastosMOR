require File.dirname(__FILE__) + '/../test_helper'
require 'gastosgem_utils'

class UserTest < Test::Unit::TestCase

  def test_invalid_with_blank_attributes
    user = User.new
    assert !user.valid?
    assert user.errors.invalid?(:first_name)
    assert user.errors.invalid?(:last_name)
    assert user.errors.invalid?(:password)
    assert user.errors.invalid?(:password_confirmation)
    assert user.errors.invalid?(:email)
    assert user.errors.invalid?(:enterprise_id)
    assert user.errors.invalid?(:supervisor_id)
  end

  def test_invalid_with_used_email
    @user = User.find(:first)
    user = new_user
    user.email = @user.email
    user.enterprise_id = @user.enterprise_id
    user.supervisor_id = @user.id
    assert !user.valid?
    assert !user.errors.invalid?(:first_name)
    assert !user.errors.invalid?(:last_name)
    assert !user.errors.invalid?(:password)
    assert !user.errors.invalid?(:password_confirmation)
    assert user.errors.invalid?(:email)
    assert !user.errors.invalid?(:enterprise_id)
    assert !user.errors.invalid?(:enterprise)
    assert !user.errors.invalid?(:supervisor_id)
    assert !user.errors.invalid?(:supervisor)
  end

  def test_invalid_with_inexistent_enterprise_and_supervisor
    user = new_user
    user.email = 'baz@baz.com'
    user.enterprise_id = 10000
    user.supervisor_id = 20000
    assert !user.valid?
    assert !user.errors.invalid?(:first_name)
    assert !user.errors.invalid?(:last_name)
    assert !user.errors.invalid?(:password)
    assert !user.errors.invalid?(:password_confirmation)
    assert !user.errors.invalid?(:email)
    assert !user.errors.invalid?(:enterprise_id)
    assert user.errors.invalid?(:enterprise)
    assert !user.errors.invalid?(:supervisor_id)
    assert user.errors.invalid?(:supervisor)
  end

  def test_valid_user
    @enterprise = Enterprise.find_by_short_name('foo')
    user = new_user
    user.email = 'baz@baz.com'
    user.email_confirmation= 'baz@baz.com'
    user.enterprise = @enterprise
    user.supervisor = @enterprise.account_owner
    assert user.valid?
    assert user.save
  end

  def test_account_owner_profiles
    @enterprise = Enterprise.find_by_short_name('foo')
    @account_owner = @enterprise.account_owner
    @account_owner.is_administrator = false
    @account_owner.is_supervisor = false
    @account_owner.is_payer = false
    assert !@account_owner.valid?
    assert @account_owner.errors.invalid?(:is_administrator)
    assert @account_owner.errors.invalid?(:is_supervisor)
    assert @account_owner.errors.invalid?(:is_payer)
  end

  private
  
  def new_user
    User.new :first_name => 'Baz', :last_name => 'Baz', 
      :password => 'bazbaz', :password_confirmation => 'bazbaz'
  end

end
