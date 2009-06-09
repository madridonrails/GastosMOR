class ExportController < ApplicationController
  require 'spreadsheet/excel'
  require 'stringio'
  require 'tempfile'
  require 'csv'
  
  def index
  end
  
  def parse_form
    @export = Export.new(params[:export])
    if @export.valid?
      # Create tempfile for xls
      tmp = Tempfile.new(@current_user.id)
      
      if @export.format == 'xls' && @export.create_xls(@current_user,tmp)
        send_data(tmp.read,
          :type => 'application/vnd.ms-excel',
          :filename => 'export.xls',
          :disposition => 'inline')
        #el informe no produce cambio de p�gina por lo que este mensaje se arrastrar�a a la siguiente p�gina flash[:notice]="Informe generado correctamente, formato xls"
      elsif  @export.format == 'csv' && @export.create_csv(@current_user,tmp)
        send_data(tmp.read,
          :type => 'application/vnd.ms-excel',
          :filename => 'export.csv',
          :disposition => 'inline')
        #el informe no produce cambio de p�gina por lo que este mensaje se arrastrar�a a la siguiente p�gina flash[:notice]="Informe generado correctamente, formato csv"
      else
        flash[:notice]="El informe no se ha creado correctamente"
        render :action => 'index'
      end
      tmp.unlink  # Delete and closes filetemp
    else
      render :action => 'index'
    end  
  end  
end
