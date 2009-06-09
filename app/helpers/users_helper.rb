module UsersHelper
  include AjaxScaffold::Helper
  
  def administrator_check_box_or_icon(user)
    if user.is_account_owner?
      'S'
    else
      check_box('user', 'is_administrator')
    end
  end

  def num_columns
    scaffold_columns.length + 1 
  end
  
  def scaffold_columns
    User.scaffold_columns
  end
end
