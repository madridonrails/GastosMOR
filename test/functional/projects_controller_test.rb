require File.dirname(__FILE__) + '/../test_helper'
require 'projects_controller'

# Re-raise errors caught by the controller.
class ProjectsController; def rescue_action(e) raise e end; end

class ProjectsControllerTest < Test::Unit::TestCase

  def setup
    @controller = ProjectsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # set mailer to append mail to deliveries instead of sending it
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    @deliveries = ActionMailer::Base.deliveries = []
  end

  def test_redirected_to_login
    @request.host = "foo.#{DOMAIN_NAME}"
    post :create, :project => {:name => 'Foo', :description => 'Foo', :supervisor_id => '1'}
    assert_redirected_to :controller => 'admin', :action => 'signin'
  end

  def test_create_non_xhr
    @with_overflow = false
    find_enterprise_and_user
    post :create, :project => {:name => 'Foo', :description => 'Foo', :supervisor_id => @user.id}
    assert_redirected_to :action => 'list'
    assert_project_added
  end

  def test_create_xhr
    @with_overflow = false
    find_enterprise_and_user
    xhr :post, :create, :project => {:name => 'Foo', :description => 'Foo', :supervisor_id => @user.id},
      :id => '1171127427202', :scaffold_id => 'project'
    assert_response :success
    assert_template 'create.rjs'
    assert_project_added
  end
  
  private
  
  def find_enterprise_and_user
    if @with_overflow
      @request.host = "bar.#{DOMAIN_NAME}"
      @enterprise = Enterprise.find_by_short_name('bar')
    else
      @request.host = "foo.#{DOMAIN_NAME}"
      @enterprise = Enterprise.find_by_short_name('foo')
    end
    @user = @enterprise.users.find(:first, :conditions => ['is_administrator = ?', 1])
    count_projects
    @request.session[:user] = @user.id
  end

  def count_projects
    @projects_count = @enterprise.projects.count
    @supervised_projects_count = @user.supervised_projects.count
  end

  def assert_project_added
    assert_equal @projects_count + 1, @enterprise.projects.count
    assert_equal @supervised_projects_count + 1, @user.supervised_projects.count
  end
  
end
