require File.dirname(__FILE__) + '/../test_helper'
require 'users_controller'

# Re-raise errors caught by the controller.
class UsersController; def rescue_action(e) raise e end; end

class UsersControllerTest < Test::Unit::TestCase

  def setup
    @controller = UsersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    # set mailer to append mail to deliveries instead of sending it
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    @deliveries = ActionMailer::Base.deliveries = []
  end

  def test_redirected_to_login
    @request.host = "foo.#{DOMAIN_NAME}"
    post :create, :user => {:is_gestor => 'false', :is_blocked => 'false', :password_confirmation => 'pepe', 
                            :is_payer => 'false', :is_administrator => 'false', :supervisor_id => '1', 
                            :is_supervisor => 'false', :first_name => 'Pepe', :last_name => 'Foo', :password => 'pepepe', 
                            :email => 'pepe@foo.com'}
    assert_redirected_to :controller => 'admin', :action => 'signin'
  end

  def test_create_non_xhr
    @with_overflow = false
    find_enterprise_and_users
    post :create, :user => {:is_gestor => 'false', :is_blocked => 'false', :password_confirmation => 'foobar', 
                            :is_payer => 'false', :is_administrator => 'false', :supervisor_id => @supervisor.id, 
                            :is_supervisor => 'false', :first_name => 'Foo', :last_name => 'Bar', :password => 'foobar', 
                            :email => 'foo@bar.com', :email_confirmation => 'foo@bar.com'}
    assert_redirected_to :action => 'list'
    assert_user_added_and_activated
  end

  def test_create_xhr
    @with_overflow = false
    find_enterprise_and_users
      xhr :post, :create, :user => {:is_gestor => 'false', :is_blocked => 'false', :password_confirmation => 'foobar', 
                                    :is_payer => 'false', :is_administrator => 'false', :supervisor_id => @supervisor.id,
                                    :is_supervisor => 'false', :first_name => 'Foo', :last_name => 'Bar', :password => 'foobar', 
                                    :email => 'foo@bar.com', :email_confirmation => 'foo@bar.com'},
      :id => '1171127427202', :scaffold_id => 'user'
    assert_response :success
    assert_template 'create.rjs'
    assert_user_added_and_activated
  end

  def test_import_no_file
    @with_overflow = false
    find_enterprise_and_users
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => ''}
    assert_import_response
    assert_equal 1, @errors.size
    assert_match %r{El fichero es un campo obligatorio}, @errors[:base]
    assert_equal @users_count, @enterprise.users.count
  end

  def test_import_invalid_headers
    @with_overflow = false
    find_enterprise_and_users
    @data = <<-END_CSV.gsub(/^\s+/, "")
      email,foos,bars
      csv@foo.com,foos,bars
    END_CSV
    @csv = StringIO.new(@data)
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => @csv}
    assert_import_response
    assert_equal 1, @errors.size
    assert_match %r{Las cabeceras del fichero no son correctas}, @errors[:base]
    assert_equal @users_count, @enterprise.users.count
  end

  def test_import_invalid_data
    @with_overflow = false
    find_enterprise_and_users
    @data = <<-END_CSV.gsub(/^\s+/, "")
      email,nombre,apellidos,password,supervisor,administrador,pagador,gestor,email supervisor
      bar@foo.com,Csv,Foo,csvcsv,0,0,0,0,foo@foo.com
      csv99@foo.com,Csv2,Foo,csvcsv,2,3,4,5,bar@bar.com
    END_CSV
    @csv = StringIO.new(@data)
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => @csv}
    assert_import_response
    assert_equal 6, @errors.size
    @messages = @errors[:base]
    assert_match %r{Línea 1.*Ya existe un usuario con email.*bar@foo.com}, @messages[0]
    assert_match %r{Línea 2.*columna supervisor.*2.*no es válido}, @messages[1]
    assert_match %r{Línea 2.*columna administrador.*3.*no es válido}, @messages[2]
    assert_match %r{Línea 2.*columna pagador.*4.*no es válido}, @messages[3]
    assert_match %r{Línea 2.*columna gestor.*5.*no es válido}, @messages[4]
    assert_match %r{Línea 2.*No se encuentra.*email.*bar@bar.com.*perfil supervisor}, @messages[5]
    assert_equal @users_count, @enterprise.users.count
  end

  def test_import_valid
    @with_overflow = false
    find_enterprise_and_users
    @data = <<-END_CSV.gsub(/^\s+/, "")
      email,nombre,apellidos,password,supervisor,administrador,pagador,gestor,email supervisor
      csv2@foo.com,Csv,Foo,csvcsv,1,0,0,0,#{@user.email}
      csv3@foo.com,Csv2,Foo,csvcsv,0,0,0,0,#{@user.email}
    END_CSV
    @csv = StringIO.new(@data)
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => @csv}
    assert_import_response
    assert_equal 0, @errors.size
    assert_equal @users_count + 2, @enterprise.users.count
    assert_imported_user_data('csv2@foo.com', 'Csv Foo', true, false, false, false, @user.email) 
    assert_imported_user_data('csv3@foo.com', 'Csv2 Foo', false, false, false, false, @user.email) 
  end

  private

  def find_enterprise_and_users
    if @with_overflow
      @request.host = "bar.#{DOMAIN_NAME}"
      @enterprise = Enterprise.find_by_short_name('bar')
      @supervisor = @user = @enterprise.users.find(:first)
    else
      @request.host = "foo.#{DOMAIN_NAME}"
      @enterprise = Enterprise.find_by_short_name('foo')
      @user = @enterprise.users.find(:first, :conditions => ['is_administrator = ?', 1])
      @supervisor = @enterprise.users.find(:first, :conditions => ['is_administrator = ? and is_supervisor = ?', 0, 1])
    end
    count_users
    @request.session[:user] = @user.id
  end

  def count_users
    @users_count = @enterprise.users.count
    @supervised_users_count = @supervisor.supervised_users.count
  end
  
  def assert_user_added_and_activated
    assert_equal @users_count + 1, @enterprise.users.count
    assert_equal @supervised_users_count + 1, @supervisor.supervised_users.count
    @new_user = User.find_by_email('foo@bar.com')
    assert_not_nil @new_user.activated_at
    assert_nil @new_user.activation_code
  end

  def assert_import_response
    assert_response :success
    assert_template 'import_csv.rjs'
    assert_not_nil assigns['user']
    @errors = assigns['user'].errors
  end

  def assert_imported_user_data(email, *data)
    user = @enterprise.users.find_by_email(email)
    assert_equal data[0], user.print_name
    assert data[1] ? user.is_supervisor? : !user.is_supervisor?
    assert data[2] ? user.is_administrator? : !user.is_administrator?
    assert data[3] ? user.is_payer? : !user.is_payer?
    assert data[4] ? user.is_gestor? : !user.is_gestor?
    assert_equal data[5], user.supervisor.email
  end
  
end
