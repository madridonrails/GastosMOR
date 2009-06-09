require File.dirname(__FILE__) + '/../test_helper'
require 'expenses_controller'

# Re-raise errors caught by the controller.
class ExpensesController; def rescue_action(e) raise e end; end

class ExpensesControllerTest < Test::Unit::TestCase

  def setup
    @controller = ExpensesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "foo.#{DOMAIN_NAME}"
  end

  def test_redirected_to_login
    post :approve, :id => '4', :page => '1', :scaffold_id => 'expense', :sort_direction => 'asc'
    assert_redirected_to :controller => 'admin', :action => 'signin'
  end

  def test_approve_non_xhr
    find_enterprise_user_and_expense
    post :approve, :id => @expense.id, :page => '1'
    assert_redirected_to :action => 'list_pending'
    assert_expense_approved
  end

  def test_approve_xhr
    find_enterprise_user_and_expense
    xhr :post, :approve, :id => @expense.id, :page => '1', :scaffold_id => 'expense'
    assert_response :success
    assert_template 'approve.rjs'
    assert_expense_approved
  end

#  def test_reject_non_xhr
#    find_enterprise_user_and_expense
#    post :reject, :id => @expense.id, :expense => {:revision_note => 'Invalid'}, :page => '1'
#    assert_redirected_to :action => 'list_pending'
#    assert @expense.reload.approved?
#  end

  def test_reject_xhr
    find_enterprise_user_and_expense
    xhr :post, :reject, :id => @expense.id, :expense => {:revision_note => 'Invalid'}, :page => '1', :scaffold_id => 'expense'
    assert_response :success
    assert_template 'reject.rjs'
    assert @expense.reload.rejected?
  end

  private
  
  def find_enterprise_user_and_expense
    @enterprise = Enterprise.find_by_short_name('foo')
    @user = @enterprise.users.find_by_email('bar@foo.com')
    @supervisor = @user.supervisor
    @expense = @user.expenses.find(:first, :conditions => ['status = ?', 'pending'])
    @request.session[:user] = @supervisor.id
  end

  def assert_expense_approved
    assert @expense.reload.approved?
    assert_expense_revised
  end

  def assert_expense_rejected
    assert @expense.reload.rejected?
    assert_expense_revised
  end

  def assert_expense_revised
    assert_equal @supervisor.id, @expense.revised_by
    assert_not_nil @expense.revised_at
  end

end
