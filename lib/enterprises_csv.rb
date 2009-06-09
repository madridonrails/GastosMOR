require 'csv'

norm = lambda {|str| Iconv.conv("ISO-8859-1//TRANSLIT//IGNORE", "UTF-8", str)}

file = File.new(File.join(RAILS_ROOT, 'enterprises.csv'), 'w')

head = ["id", "Nombre corto", "Mail Propietario", "Activa", "Bloqueada", "Nombre", "Dirección", "Ciudad", "Provincia", "Código postal", 
          "País", "cif"]

CSV::Writer.generate(file, ",") do |csv|
  csv << head.map {|h| norm.call(h)}
  Enterprise.find(:all, :include => [:country]).each do |e|
    csv << [ e.id, e.short_name, e.account_owner.email, e.is_active, e.is_blocked, e.name, e.address, e.city, e.province,
             e.postal_code, e.country.name, e.cif
           ].map {|r| norm.call(r.to_s)}
  end
end
file.rewind
