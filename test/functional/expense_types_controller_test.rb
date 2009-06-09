require File.dirname(__FILE__) + '/../test_helper'
require 'expense_types_controller'

# Re-raise errors caught by the controller.
class ExpenseTypesController; def rescue_action(e) raise e end; end

class ExpenseTypesControllerTest < Test::Unit::TestCase

  def setup
    @controller = ExpenseTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "foo.#{DOMAIN_NAME}"
  end

  def test_redirected_to_login
    post :create, :expense_type => {:description =>'Foo', :parent_id => '1'}
    assert_redirected_to :controller => 'admin', :action => 'signin'
  end

  def test_create_non_xhr
    @with_parent = true
    find_enterprise_user_and_parent
    post :create, :expense_type => {:description =>'Foo', :parent_id => @parent.id}
    assert_redirected_to :action => 'list'
    assert_expense_type_added
  end

  def test_create_xhr
    @with_parent = true
    find_enterprise_user_and_parent
    xhr :post, :create, :expense_type => {:description =>'Foo', :parent_id => @parent.id}
    assert_response :success
    assert_template 'create.rjs'
    assert_expense_type_added
  end

  def test_create_without_parent
    @with_parent = false
    find_enterprise_user_and_parent
    xhr :post, :create, :expense_type => {:description =>'Foo', :parent_id => ''}
    assert_response :success
    assert_template 'create.rjs'
    assert_expense_type_added
  end

  private
  
  def find_enterprise_user_and_parent
    @enterprise = Enterprise.find_by_short_name('foo')
    @user = @enterprise.users.find(:first, :conditions => ['is_administrator = ?', 1])
    @parent = @enterprise.expense_types.find(:first) if @with_parent
    count_expense_types
    @request.session[:user] = @user.id
  end

  def count_expense_types
    @expense_types_count = @enterprise.expense_types.count
    @parent_types_count = @parent.children.count if @with_parent
  end

  def assert_expense_type_added
    assert_equal @expense_types_count + 1, @enterprise.expense_types.count
    assert_equal @parent_types_count + 1, @parent.children.count if @with_parent
  end

end
