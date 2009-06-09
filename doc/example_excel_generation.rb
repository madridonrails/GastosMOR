# To be executed with
#
# ruby script/runner 'require "doc/example_excel_generation"'
#

require "spreadsheet/excel"
require 'stringio'

# This is fake data just to show off how to build the Excel file in memory. In
# the real application that would come from actual models and fields may
# differ.
expenses = [
 ["hotel Bruselas", "300", "aprobado"],
 ["avion Bruselas", "1000", "aprobado"],
 ["cenorro que te pasas", "200", "rechazado"]
]

payments = [
  ["viaje a Bruselas", "1300"]
]

workbook = Spreadsheet::Excel.new("eraseme.xls")

expenses_worksheet = workbook.add_worksheet('Gastos')
expenses_worksheet.write(0, 0, ["Nota", "Cantidad", "Estado"])
expenses.each_with_index {|data, i| expenses_worksheet.write(i+1, 0, data)}

payments_worksheet = workbook.add_worksheet('Pagos')
payments_worksheet.write(0, 0, ["Nota", "Cantidad"])
payments.each_with_index {|data, i| payments_worksheet.write(i+1, 0, data)}

workbook.close
