class Export < ActiveRecord::Base
  def self.columns() @columns ||= []; end
  def self.column(name, sql_type = nil, default = nil, null = true)
    columns << ActiveRecord::ConnectionAdapters::Column.new(name.to_s, default, sql_type.to_s, null)
  end

  column :expenses, :boolean
  column :payments, :boolean
  column :supervised, :boolean
  column :administrator, :boolean
  column :range, :string
  column :start_date, :date
  column :end_date, :date
  column :project, :integer
  column :format, :string

  def validate
    unless expenses or payments
      errors.add(:expenses,'^Tienes que elegir que quieres exportar.')
    end

    if range == 'dates' && !Date.valid_date?(start_date.year,start_date.mon,start_date.day)
      errors.add(:date,'^La fecha de inicio no es válida.')
    end
    if range == 'dates' && !Date.valid_date?(end_date.year,end_date.mon,end_date.day)
      errors.add(:date,'^La fecha de inicio no es válida.')
    end
    if (project && !Project.find_by_id(project))
      errors.add(:project,'^Proyecto inexistente, seleccione uno de la lista')
    end
    unless format == 'xls' or format== 'csv'
      errors.add(:format,'^Tienes que elegir en que formato quieres exportar.')
    end
  end
  
  def create_xls(user,file)
    #open files
    workbook = Spreadsheet::Excel.new(file.path)   
          
    #Select data:
    expenses = select_expenses(user) if self.expenses
    payments = select_payments(user) if self.payments
        
    # Create worksheets
    worksheet = workbook.add_worksheet('Listado')

    # Header
    format_row = Format.new(:size=>11)
    worksheet.write_row(0, 0, head)

    # Index for data
    @index = 1

    # Write expenses in worksheet:
    if self.expenses
      expenses.each_with_index {|data, i| 
        worksheet.write_row(@index,0,expense_row(data),format_row)
        @index += 1
      }
    end
    
    
    # Write payments in workshett
    if self.payments
      payments.each_with_index {|data, i|
          worksheet.write_row(@index,0,payment_row(data),format_row)
          @index +=1
      }
    end                               
    workbook.close
  end  
  
  def create_csv(user,file)
    # Select data
    expenses = select_expenses(user) if self.expenses
    payments = select_payments(user) if self.payments
    
    CSV::Writer.generate(file,"\t") do |csv|
      csv << head
      expenses.each do |data|   
        csv << expense_row(data)
      end if self.expenses
      payments.each do |data|
        csv << payment_row(data)
      end if self.payments
    end
    file.rewind
  end
  
private
  def head
    [
     f('ID'),f('Gasto/Pago'),f('Estado'),
     f('Usuario'),f('Email usuario'),f('Proyecto'),f('Fecha'),
     f('Tipo de gastos/Concepto'),f('Descripción'),f('Cantidad'), 
     f('Comentarios'),f('Fecha alta'), f('Fecha actualización'),
     f('Sobre'),f('Forma de pago'),f('Nota de revisión'),
     f('Pagado por'),f('Email pagado por')
    ]
  end
  
  def expense_row (data)
    [
     data.id,'GASTO',f(data.status_translated),
     f(data.user.first_name.to_s+' '+data.user.last_name.to_s),f(data.user.email),f((data.project ? data.project.name.to_s : '')),f(data.date.to_s),
     f((data.expense_type ? data.expense_type.description.to_s : '')),f(data.description),format_amount_as_decimal(data.amount),
     f(data.comments),f(data.created_at.to_s), f(data.updated_at.to_s),
     f(data.envelope), f(PaymentType::combo[data.payment_type][0]),f(data.revision_note),
     '',''
    ]
  end
  
  def payment_row (data)
    [
    data.id,'PAGO',f('Pagado'),
    f(data.user.first_name.to_s+' '+data.user.last_name.to_s),f(data.user.email),'',f(data.date.to_s),
    f(data.concept),f(data.description),format_amount_as_decimal(data.amount),
    '','','',
    '','','',
    f(data.orderer.first_name.to_s+' '+data.orderer.last_name.to_s),f(data.orderer.email)
    ]
  end

  def select_expenses(user)
    if range == 'all'
      expenses = user.expenses
      if supervised   # all expenses show the supervised.
        expenses += user.supervised_projects.collect {|p| 
                      p.expenses
                    }.flatten if user.supervised_projects_count > 0
        expenses += user.supervised_users.collect {|u|
                      u.expenses
                    }.flatten if user.supervised_users_count > 0
        expenses.uniq!
      end
      # Administrator can export all data for her enterprise.
      if administrator || user.is_gestor?
        user_ids = user.enterprise.users.collect {|u| u.id}.flatten
        expenses = Expense.find(:all,
          :conditions => ["user_id IN (?)",user_ids])      
      end
    elsif range == 'dates'
      if supervised
        user_ids = user.supervised_users.collect {|u| u.id}.flatten
        user_ids += [user.id]
        expenses = Expense.find(:all,
          :conditions => ["user_id IN (?) AND date BETWEEN ? AND ?",user_ids,start_date,end_date])      
      else
        expenses = Expense.find(:all,
          :conditions => ["user_id= ? AND date BETWEEN ? AND ?",user,start_date,end_date])      
      end
      if administrator || user.is_gestor?
        user_ids = user.enterprise.users.collect {|u| u.id}.flatten
        expenses = Expense.find(:all, 
          :conditions => ["user_id IN (?) AND date BETWEEN ? AND ?",user_ids,start_date,end_date])      
      end
    end
    if project
      # if is supervisor show all expenses of project, else show only owns.
      if self.expenses
        expenses = Expense.find_all_by_project_id(project)
        expenses = expenses.select{ |e| e.user == user } unless user.supervised_projects.any?{|i| i.id == project} || user.is_administrator || user.is_gestor?
      end
    end
    
    #Only approved expenses if user is gestor.
    expenses = expenses.select {|e| e.status == ExpenseStatus::APPROVED } if user.is_gestor?
    
    expenses
  end
  
  def select_payments(user)
    if range == 'all'
      payments =  if administrator || user.is_gestor?
                    users_id = user.enterprise.users.collect {|u| u.id}.flatten
                    Payment.find(:all,:conditions => ["user_id IN (?)", users_id])                  
                  elsif supervised
                    users_id = user.supervised_users.collect {|u| u.id}.flatten                    
                    users_id += [user.id]
                    Payment.find(:all,:conditions => ["user_id IN (?)", users_id])                  
                  else
                    Payment.find_all_by_user_id(user.id)
                  end
    elsif range == 'dates'
      if administrator || user.is_gestor?
        users_id = user.enterprise.users.collect {|u| u.id}.flatten
        payments = Payment.find(:all,
          :conditions => ["user_id IN (?) AND date BETWEEN ? AND ?",users_id,start_date,end_date])
      elsif supervised
        users_id = user.supervised_users.collect {|u| u.id}.flatten
        users_id += [user.id]

        payments = Payment.find(:all,
          :conditions => ["user_id IN (?) AND date BETWEEN ? AND ?",users_id,start_date,end_date])
      else    
        payments = Payment.find(:all,
          :conditions => ["user_id= ? AND date BETWEEN ? AND ?",user,start_date,end_date])
      end
    elsif range == 'projects'
      # payments don't have relation with the projects then show all
      payments = if administrator || user.is_gestor?
                   users_id = user.enterprise.users.collect {|u| u.id}.flatten
                   Payment.find(:all,:conditions => ["user_id IN (?)", users_id])                  
                 else
                   Payment.find_all_by_user_id(user.id)
                 end
    end
    payments
  end
  
  def format_amount_as_decimal(am,pos=2)
    am = am.to_s
    
    am = (am[0,am.size-pos] +'.'+am[am.size-pos,am.size]).to_f unless am == '0'
    am.to_f

  end
  
  private
  def f(s)
    Iconv.conv("ISO-8859-1", "UTF-8", s)
  end
end
