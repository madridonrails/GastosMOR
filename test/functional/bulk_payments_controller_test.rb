require File.dirname(__FILE__) + '/../test_helper'
require 'bulk_payments_controller'

# Re-raise errors caught by the controller.
class BulkPaymentsController; def rescue_action(e) raise e end; end

class BulkPaymentsControllerTest < Test::Unit::TestCase

  def setup
    @controller = BulkPaymentsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "foo.#{DOMAIN_NAME}"
  end

  def test_redirected_to_login
    post :create, :bulk_payment => {'date(1i)' => '2007', 'date(2i)' => '2', 'date(3i)' => '10',
                                    :description => 'foo', :amount => '99', :concept => 'foo', 
                                    :user_id => 2, :ordered_by => 1}
    assert_redirected_to :controller => 'admin', :action => 'signin'
  end

  def test_create_non_xhr
    find_enterprise_and_users
    payments_count = @user.payments.count
    ordered_payments_count = @payer.ordered_payments.count
    post :create, :bulk_payment => {'date(1i)' => '2007', 'date(2i)' => '2', 'date(3i)' => '10',
                                    :description => 'foo', :amount => '99', :concept => 'foo',
                                    :user_id => @user.id, :ordered_by => @payer.id,}
    assert_redirected_to :controller => 'payments', :action => 'list'
    assert_payment_added
  end

  def test_create_xhr
    find_enterprise_and_users
    payments_count = @user.payments.count
    ordered_payments_count = @payer.ordered_payments.count
    xhr :post, :create, :bulk_payment => {'date(1i)' => '2007', 'date(2i)' => '2', 'date(3i)' => '10',
                                          :description => 'foo', :amount => '99', :concept => 'foo',
                                          :user_id => @user.id, :ordered_by => @payer.id,},
      :id => '1171127427202', :scaffold_id => 'bulk_payment'
    assert_response :success
    assert_template 'create.rjs'
    assert_payment_added
  end

  def test_import_no_file
    find_enterprise_and_users
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => ''}
    assert_import_response
    assert_equal 1, @errors.size
    assert_match %r{El fichero es un campo obligatorio}, @errors[:base]
    assert_equal @ordered_payments_count, @payer.ordered_payments.count
  end

  def test_import_invalid_headers
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
    assert_equal @ordered_payments_count, @payer.ordered_payments.count
  end

  def test_import_invalid_data
    find_enterprise_and_users
    @data = <<-END_CSV.gsub(/^\s+/, "").gsub('@user.email', @user.email)
      fecha,cantidad,concepto,pagado a,descripción
      2007-02-30,"123.456.789,01",Concept,invalid@foo.com,description
      12-02/2007,"123.456,789.01",Concept,@user.email,description
    END_CSV
    @csv = StringIO.new(@data)
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => @csv}
    assert_import_response
    assert_equal 4, @errors.size
    @messages = @errors[:base]
    assert_match %r{Línea 1.*La fecha.*2007-02-30.*no es válida}, @messages[0]
    assert_match %r{Línea 1.*No se encuentra.*email.*invalid@foo.com}, @messages[1]
    assert_match %r{Línea 2.*La fecha.*12-02/2007.*no es válida}, @messages[2]
    assert_match %r{Línea 2.*La cantidad.*123.456,789.01.*no es válida}, @messages[3]
    assert_equal @ordered_payments_count, @payer.ordered_payments.count
  end

  def test_import_valid
    find_enterprise_and_users
    @data = <<-END_CSV.gsub(/^\s+/, "")
      fecha,cantidad,concepto,pagado a,descripción
      2007-02-17,"89,01",Concept 1,#{@user.email},description 1
      18-02-07,"123.45",Concept 2,#{@payer.email},description 2
      19/02/2007,"50,99",Concept 3,#{@user.email},description 3
    END_CSV
    @csv = StringIO.new(@data)
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => @csv}
    assert_import_response
    assert_equal 0, @errors.size
    assert_equal @payments_count + 2, @user.payments.count
    assert_equal @ordered_payments_count + 3, @payer.ordered_payments.count
    assert_equal @payer_payments_count + 1, @payer.payments.count
    assert_imported_payment_data('Concept 1', Date.new(2007, 02, 17), 8901, @user.email, 'description 1')
    assert_imported_payment_data('Concept 2', Date.new(2007, 02, 18), 12345, @payer.email, 'description 2')
    assert_imported_payment_data('Concept 3', Date.new(2007, 02, 19), 5099, @user.email, 'description 3')
  end

  private

  def find_enterprise_and_users
    @enterprise = Enterprise.find_by_short_name('foo')
    @user = @enterprise.users.find(:first, :conditions => ['is_payer = ?', 0])
    @payer = @enterprise.users.find(:first, :conditions => ['is_payer = ?', 1])
    count_payments
    @request.session[:user] = @payer.id
  end

  def count_payments
    @payments_count = @user.payments.count
    @ordered_payments_count = @payer.ordered_payments.count
    @payer_payments_count = @payer.payments.count
  end
  
  def assert_payment_added
    assert_equal @payments_count + 1, @user.payments.count
    assert_equal @ordered_payments_count + 1, @payer.ordered_payments.count
  end

  def assert_import_response
    assert_response :success
    assert_template 'import_csv.rjs'
    assert_not_nil assigns['bulk_payment']
    @errors = assigns['bulk_payment'].errors
  end
  
  def assert_imported_payment_data(concept, *data)
    payment = @payer.ordered_payments.find_by_concept(concept)
    assert_equal data[0], payment.date
    assert_equal data[1], payment.amount
    assert_equal data[2], payment.user.email
    assert_equal data[3], payment.description
  end
  
end
