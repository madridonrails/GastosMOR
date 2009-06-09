require File.dirname(__FILE__) + '/../test_helper'
require 'bulk_expenses_controller'

# Re-raise errors caught by the controller.
class BulkExpensesController; def rescue_action(e) raise e end; end

class BulkExpensesControllerTest < Test::Unit::TestCase
  
  def setup
    @controller = BulkExpensesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = "foo.#{DOMAIN_NAME}"
  end

  def test_redirected_to_login
    post :create, :bulk_expense => {:status => 'pending', :project_id => 1, 'date(1i)' => '2007', 
                                    'date(2i)' => '2', 'date(3i)' => '10', :envelope => 'Foo Foo febrero 001', 
                                    :description => 'foo', :amount => '99', :expense_type_id => 1, 
                                    :user_id => 1, :payment_type => '0'}
    assert_redirected_to :controller => 'admin', :action => 'signin'
  end

  def test_create_non_xhr
    find_enterprise_user_project_and_expense_type
    expenses_count = @user.expenses.count
    post :create, :bulk_expense => {:status => 'pending', :project_id => @project.id, 'date(1i)' => '2007', 
                                    'date(2i)' => '2', 'date(3i)' => '10', :envelope => 'Foo Foo febrero 001', 
                                    :description => 'foo', :amount => '99', :expense_type_id => @expense_type.id, 
                                    :user_id => @user.id, :payment_type => '0'}
    assert_redirected_to :controller => 'expenses', :action => 'list'
    assert_expense_added
  end

  def test_create_xhr
    find_enterprise_user_project_and_expense_type
    xhr :post, :create, :bulk_expense => {:status => 'pending', :project_id => @project.id, 'date(1i)' => '2007', 
                                         'date(2i)' => '2', 'date(3i)' => '10', :envelope => 'Foo Foo febrero 001', 
                                         :description => 'foo', :amount => '99', :expense_type_id => @expense_type.id, 
                                         :user_id => @user.id, :payment_type => '0'},
      :id => '1171127427202', :scaffold_id => 'bulk_expense'
    assert_response :success
    assert_template 'create.rjs'
    assert_expense_added
  end

  def test_import_no_file
    find_enterprise_user_project_and_expense_type
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => ''}
    assert_import_response
    assert_equal 1, @errors.size
    assert_match %r{El fichero es un campo obligatorio}, @errors[:base]
    assert_equal @user_expenses_count, @user.expenses.count
  end

  def test_import_invalid_headers
    find_enterprise_user_project_and_expense_type
    @data = <<-END_CSV.gsub(/^\s+/, "")
      email,foos,bars
      csv@foo.com,foos,bars
    END_CSV
    @csv = StringIO.new(@data)
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => @csv}
    assert_import_response
    assert_equal 1, @errors.size
    assert_match %r{Las cabeceras del fichero no son correctas}, @errors[:base]
    assert_equal @user_expenses_count, @user.expenses.count
  end

  def test_import_invalid_data
    find_enterprise_user_project_and_expense_type
    @data = <<-END_CSV.gsub(/^\s+/, "").gsub('@expense_type.description', @expense_type.description).gsub('@project.name', @project.name)
      fecha,concepto,importe,sobre,forma pago,tipo,proyecto
      2007-02-30,Concept,"123.456.789,01",Feb_001,Efectivo,invalid type,invalid project
      12-02/2007,Concept,"123.456,789.01",Feb_001,Cheque,@expense_type.description,@project.name
    END_CSV
    @csv = StringIO.new(@data)
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => @csv}
    assert_import_response
    assert_equal 6, @errors.size
    @messages = @errors[:base]
    assert_match %r{Línea 1.*La fecha.*2007-02-30.*no es válida}, @messages[0]
    assert_match %r{Línea 1.*No se encuentra.*tipo de gastos.*invalid type}, @messages[1]
    assert_match %r{Línea 1.*No se encuentra.*proyecto.*invalid project}, @messages[2]
    assert_match %r{Línea 2.*La fecha.*12-02/2007.*no es válida}, @messages[3]
    assert_match %r{Línea 2.*El importe.*123.456,789.01.*no es válido}, @messages[4]
    assert_match %r{Línea 2.*No se encuentra.*forma de pago.*Cheque}, @messages[5]
    assert_equal @user_expenses_count, @user.expenses.count
  end

  def test_import_valid
    find_enterprise_user_project_and_expense_type
    @data = <<-END_CSV.gsub(/^\s+/, "")
      fecha,concepto,importe,sobre,forma pago,tipo,proyecto
      2007-02-17,Concept 1,"123,50",Feb_001,Efectivo,#{@expense_type2.description},#{@project2.name}
      18/02/07,Concept 2,"45,60",Feb_002,Efectivo,#{@expense_type.description},#{@project.name}
      19-02-2007,Concept 3,"90.05",Feb_003,Tarjeta de empresa,#{@expense_type.description},#{@project.name}
    END_CSV
    @csv = StringIO.new(@data)
    xhr :post, :import_csv, :csv => {:file_temp => '', :file => @csv}
    assert_import_response
    assert_equal 0, @errors.size
    assert_equal @user_expenses_count + 3, @user.expenses.count
    assert_equal @project_expenses_count + 2, @project.expenses.count
    assert_equal @expense_type_expenses_count + 2, @expense_type.expenses.count
    assert_equal @project2_expenses_count + 1, @project2.expenses.count
    assert_equal @expense_type2_expenses_count + 1, @expense_type2.expenses.count
    assert_imported_expense_data('Concept 1', Date.new(2007, 02, 17), 12350, 'Feb_001', 'Efectivo', @expense_type2.description, @project2.name)
    assert_imported_expense_data('Concept 2', Date.new(2007, 02, 18), 4560, 'Feb_002', 'Efectivo', @expense_type.description, @project.name)
    assert_imported_expense_data('Concept 3', Date.new(2007, 02, 19), 9005, 'Feb_003', 'Tarjeta de empresa', @expense_type.description, @project.name)
  end

  private

  def find_enterprise_user_project_and_expense_type
    @enterprise = Enterprise.find_by_short_name('foo')
    @user = @enterprise.users[0]
    @project = @enterprise.projects[0]
    @expense_type = @enterprise.expense_types[0]
    @project2 = @enterprise.projects[1]
    @expense_type2 = @enterprise.expense_types[1]
    count_expenses
    @request.session[:user] = @user.id
  end

  def count_expenses
    @user_expenses_count = @user.expenses.count
    @project_expenses_count = @project.expenses.count
    @expense_type_expenses_count = @expense_type.expenses.count
    @project2_expenses_count = @project2.expenses.count
    @expense_type2_expenses_count = @expense_type2.expenses.count
  end

  def assert_expense_added
    assert_equal @user_expenses_count + 1, @user.expenses.count
    assert_equal @project_expenses_count + 1, @project.expenses.count
    assert_equal @expense_type_expenses_count + 1, @expense_type.expenses.count
  end

  def assert_import_response
    assert_response :success
    assert_template 'import_csv.rjs'
    assert_not_nil assigns['bulk_expense']
    @errors = assigns['bulk_expense'].errors
  end
  
  def assert_imported_expense_data(concept, *data)
    expense = @user.expenses.find_by_description(concept)
    assert_equal data[0], expense.date
    assert_equal data[1], expense.amount
    assert_equal data[2], expense.envelope
    assert_equal data[3], PaymentType.find_by_id(expense.payment_type)
    assert_equal data[4], expense.expense_type.description
    assert_equal data[5], expense.project.name
  end
  
end
