require File.dirname(__FILE__) + '/../test_helper'
require 'public_controller'

# Re-raise errors caught by the controller.
class PublicController; def rescue_action(e) raise e end; end

class PublicControllerTest < Test::Unit::TestCase
  def setup
    @controller = PublicController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_wrong_domain
    @request.host = "baz.#{DOMAIN_NAME}"
    get :index
    assert_not_equal @request.host, @response.headers['Location']
    assert_match(/www\.#{DOMAIN_NAME}/i, @response.headers['Location'])
    assert_redirected_to :action => 'index'
  end

  def test_reserved_not_www_domain
    @request.host = "demo.#{DOMAIN_NAME}"
    get :index
    assert_redirected_to :action => 'home'
  end
  
  def test_enterprise_subdomain
    @request.host = "foo.#{DOMAIN_NAME}"
    get :index
    assert_redirected_to :controller => 'public', :action => 'home'
  end

  def test_enterprise_subdomain_logged_in
    @request.host = "foo.#{DOMAIN_NAME}"
    @request.session[:user] = Enterprise.find_by_short_name('foo').account_owner_id
    get :index
    assert_redirected_to :action => 'home'
  end

end
