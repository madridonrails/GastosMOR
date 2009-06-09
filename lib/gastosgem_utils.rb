#
# It is VERY IMPORTANT that this file is saved in UTF-8.
#

# This library redefines String#tr so that it understands UTF-8.
require 'jcode'

module GastosgemUtils
  # Size of pages for pagination.
  PAGE_SIZE = 10 unless defined? PAGE_SIZE
  
  #Size in Kb
  LOGO_MAX_SIZE = 100 unless defined? LOGO_MAX_SIZE
  
  # Mails sent to assign new passwords have this from.
  MAIL_FROM = CONTACT_EMAIL_ACCOUNTS unless defined? MAIL_FROM
  
  THEMES=[['ASPgems','default'],['Azul','blue'],['Rojo','red']] unless defined? THEMES
  # Reserved subdomains, not available for enterprise short_name, since we use them
  # for another purpose
  RESERVED_SUBDOMAINS = %w(www foros demo test) unless defined? RESERVED_SUBDOMAINS

  # System alerts are sent to the Admin email
  ALERTS_RECEIVER = ((ENV['RAILS_ENV'] == 'production') ? CONTACT_EMAIL_ACCOUNTS : "demo@#{DOMAIN_NAME}") unless defined? ALERTS_RECEIVER
  
  # Reporting
  REPORTING_RECEIVER = ((ENV['RAILS_ENV'] == 'production') ? "facturacion@#{DOMAIN_NAME}" : "demo@#{DOMAIN_NAME}") unless defined? REPORTING_RECEIVER
  
   def self.normalize_for_sorting(s)
     return nil if s.nil?
     norm = s.downcase
     norm.tr!('ÁÉÍÓÚ', 'aeiou')
     norm.tr!('ÀÈÌÒÙ', 'aeiou')
     norm.tr!('ÄËÏÖÜ', 'aeiou')
     norm.tr!('ÂÊÎÔÛ', 'aeiou')
     norm.tr!('áéíóú', 'aeiou')
     norm.tr!('àèìòù', 'aeiou')
     norm.tr!('äëïöü', 'aeiou')
     norm.tr!('âêîôû', 'aeiou')
     norm
   end

  # The trick with iconv does not work in Acens due to the version of the library there.
  def self.normalize(str)
    return '' if str.nil?
    n = str.chars.downcase.strip.to_s
    n.gsub!(/[àáâãäåāă]/,    'a')
    n.gsub!(/æ/,            'ae')
    n.gsub!(/[ďđ]/,          'd')
    n.gsub!(/[çćčĉċ]/,       'c')
    n.gsub!(/[èéêëēęěĕė]/,   'e')
    n.gsub!(/ƒ/,             'f')
    n.gsub!(/[ĝğġģ]/,        'g')
    n.gsub!(/[ĥħ]/,          'h')
    n.gsub!(/[ììíîïīĩĭ]/,    'i')
    n.gsub!(/[įıĳĵ]/,        'j')
    n.gsub!(/[ķĸ]/,          'k')
    n.gsub!(/[łľĺļŀ]/,       'l')
    n.gsub!(/[ñńňņŉŋ]/,      'n')
    n.gsub!(/[òóôõöøōőŏŏ]/,  'o')
    n.gsub!(/œ/,            'oe')
    n.gsub!(/ą/,             'q')
    n.gsub!(/[ŕřŗ]/,         'r')
    n.gsub!(/[śšşŝș]/,       's')
    n.gsub!(/[ťţŧț]/,        't')
    n.gsub!(/[ùúûüūůűŭũų]/,  'u')
    n.gsub!(/ŵ/,             'w')
    n.gsub!(/[ýÿŷ]/,         'y')
    n.gsub!(/[žżź]/,         'z')
    n.gsub!(/\s+/,           ' ')
    n.tr!('^ a-z0-9_/\\-',    '')
    n
  end
 

# format_amount receive an amount and return it in integer.
# the formats admited are:
#   123.456,00
#   123,456.11
#   123 456,12
#   ...
#   
# Brief explain about the regex:
#^(?:\d{1,3} # 1 to 3 digits 
#(?:([, .])\d{3})? # if there is a separator it must be followed by 3 digits 
#(?:\1\d{3})* # if the is more than two groups the same separtor must but used, it must be followed by 3 digits 
#|(?:\d+)) # more than 3 digit with no comma separator 
#((?!\1)[,.]\d{2})?$ # option cents
#
  def self.format_amount(am)
    am = am.to_s
    if am =~ /^(?:\d{1,3}(?:([, .])\d{3})?(?:\1\d{3})*|(?:\d+))((?!\1)[,.]\d{1,2})?$/
      decimal = $2
      am.gsub!(decimal,'') unless decimal.nil?  # quit decimals if exist
      decimal= "00" if decimal.nil? #if not exists put zero :)
      am.gsub!(/[, .]/,'')        # quit punctuation symbols
      decimal.gsub!(/[, .]/,'')   # idem. in decimal part
      (2 - decimal.size).times do # puts zeros in decimal part
          decimal += "0"
      end
      return (am + decimal)
    else
      return nil
    end
  end

# parse_date receives a string and returns a Date.
# the formats admited are:
#   dd/mm/yy
#   dd/mm/yyyy
#   dd-mm-yy
#   dd-mm-yyyy
#   yyyy-mm-dd
#
# Brief explain about the regexps:
#
#^(\d{4}        # 4 digits
#-(\d{2})       # accept only - as separator, then 2 digits
#-(\d{2})$      # accept only - as separator, then 2 digits
#
#^(\d{2}        # 2 digits
#(/|-)          # accept both / and - as separator
#(\d{2})*       # 2 digits
#(?:\2)(\d{2})$ # the same separator as in the first case and 2 digits
#(\d{2})?$      # optionally the year can be represented with 4 digits (the previous 2 and these 2).
#
  def self.parse_date(str)
    #yyyy-mm-dd format
    if str =~ Regexp.new('^(\d{4})-(\d{2})-(\d{2})$')
      return Date.new($1.to_i, $2.to_i, $3.to_i)
    #dd(-/)mm(-/)yy(yy)
    elsif str =~ Regexp.new('^(\d{2})(/|-)(\d{2})(?:\2)(\d{2})(\d{2})?$')
      return Date.new(($4+$5).to_i, $3.to_i, $1.to_i) unless $5.nil?
      return Date.new(('20'+$4).to_i, $3.to_i, $1.to_i) if $5.nil?
    else
      return nil
    end
  end
end

