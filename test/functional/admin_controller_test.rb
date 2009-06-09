require File.dirname(__FILE__) + '/../test_helper'
require 'admin_controller'

# Re-raise errors caught by the controller.
class AdminController; def rescue_action(e) raise e end; end

class AdminControllerTest < Test::Unit::TestCase

  def setup
    @controller = AdminController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "foo.#{DOMAIN_NAME}"

    # set mailer to append mail to deliveries instead of sending it
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    @deliveries = ActionMailer::Base.deliveries = []
  end

  def test_index
    get :index
    assert_redirected_to :action => 'signin'
  end

  def test_signin
    @user = User.find_by_email('foo@foo.com')
    post :signin, :user => {:email => 'foo@foo.com'}, :password => 'foofoo'
    assert_redirected_to :controller => 'expenses', :action => 'index' #foo@foo.com is account_owner
    assert_equal @user.id, session[:user]
  end

  def test_invalid_signin
    post :signin, :user => {:email => 'foo@foo.com'}, :password => 'invalid'
    assert_response :success
    assert_template 'signin'
    assert_equal 'Usuario o password incorrecto', flash[:notice]
  end

  def test_other_subdomain_signin
    post :signin, :user => {:email => 'bar@bar.com'}, :password => 'barbar'
    assert_response :success
    assert_template 'signin'
    assert_equal 'Usuario o password incorrecto', flash[:notice]
  end

  def test_signout
    @user = User.find_by_email('foo@foo.com')
    @request.session[:user] = @user.id
    get :signout
    assert_redirected_to :action => 'signin'    
    assert_nil session[:user]
  end

  def test_new_password
    post :new_password, :user => {:email => 'foo@foo.com'}
    assert_response :success
    assert_template 'signin'
    assert_equal 1, @deliveries.size
  end

  def test_invalid_new_password
    post :new_password, :user => {:email => 'foo@baz.com'}
    assert_response :success
    assert_template 'signin'
    assert_equal 'No hay ningún usuario con email foo@baz.com', flash[:error]
    assert_equal 0, @deliveries.size
  end

end
