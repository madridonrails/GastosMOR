require File.dirname(__FILE__) + '/../test_helper'
require 'signup_controller'

# Re-raise errors caught by the controller.
class SignupController; def rescue_action(e) raise e end; end

class SignupControllerTest < Test::Unit::TestCase
  def setup
    @controller = SignupController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "www.#{DOMAIN_NAME}"

    # set mailer to append mail to deliveries instead of sending it
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    @deliveries = ActionMailer::Base.deliveries = []
  end

  def test_index
    get :index
    assert_redirected_to :controller => 'public', :action => 'home'
  end

  def test_get_create_new_user
    get :create_new_user
    assert_response :success
    assert_template 'create_new_user'
  end

  def test_signup_create_new_user
    assert_inexistent
    post :create_new_user, :enterprise => {:name => 'Baz', :country_id => '23', :short_name => 'baz'},
      :account_owner => {:password_confirmation => 'bazbaz', :first_name => 'Baz', :password => 'bazbaz', 
                         :last_name => 'Baz', :email => 'baz@baz.com',:email_confirmation => 'baz@baz.com'}, 
      :accept_terms => '1'
    assert_successfully_signup
    assert_equal 1, @deliveries.size
    get :activate, :id => @user.activation_code
    assert_successfully_activated 
    assert_equal 2, @deliveries.size
  end

  def test_invalid_signup_not_accepted_terms
    post :create_new_user, :enterprise => {:name => 'Baz', :country_id => '23', :short_name => 'baz'},
      :account_owner => {:password_confirmation => 'bazbaz', :first_name => 'Baz', :password => 'bazbaz', 
        :last_name => 'Baz', :email => 'baz@baz.com'}
    assert_response :success
    assert_template 'create_new_user'
    assert_equal 'Has de aceptar las condiciones de uso', flash[:error]
  end

  def test_invalid_signup_used_sudomain
    post :create_new_user, :enterprise => {:name => 'Foo', :country_id => '23', :short_name => 'foo'},
      :account_owner => {:password_confirmation => 'foofoo', :first_name => 'Foo', :password => 'foofoo', 
        :last_name => 'Foo', :email => 'foo@foo.com'}, 
      :accept_terms => '1'
    assert_response :success
    assert_template 'create_new_user'
    assert_equal 'Lo siento Alias repetido, elige otro', flash[:error]
  end

  def test_invalid_signup_reserved_subdomain
    post :create_new_user, :enterprise => {:name => 'Foo', :country_id => '23', :short_name => 'www'},
      :account_owner => {:password_confirmation => 'foofoo', :first_name => 'Foo', :password => 'foofoo', 
        :last_name => 'Foo', :email => 'foo@foo.com'}, 
      :accept_terms => '1'
    assert_response :success
    assert_template 'create_new_user'
    assert_equal 'Lo siento Alias repetido, elige otro', flash[:error]
  end

  private

  def assert_inexistent
    assert_nil Enterprise.find_by_short_name('baz')
    assert_nil User.find_by_email('baz@baz.com')
  end

  def assert_successfully_signup
    assert_redirected_to :action => 'success'
    find_enterprise_and_user
    assert_not_nil @enterprise
    assert_not_nil @user
    assert_equal @enterprise, @user.enterprise
    assert_equal @user, @enterprise.account_owner
    assert_nil @user.activated_at
    assert_not_nil @user.activation_code
    assert @user.is_administrator?
    assert @user.is_payer?
    assert @user.is_supervisor?
  end

  def assert_successfully_activated
    assert_redirected_to :action => 'activated', :id => @user.enterprise.short_name
    find_enterprise_and_user
    assert_not_nil @user.activated_at
    assert_nil @user.activation_code
    assert_equal 1, @enterprise.projects.count
    assert_equal 13, @enterprise.expense_types.count
  end

  def find_enterprise_and_user
    @enterprise = Enterprise.find_by_short_name('baz')
    @user = User.find_by_email('baz@baz.com')
  end

end
