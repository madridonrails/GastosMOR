class HelpController < ApplicationController

 def show
   id = params[:id]
   id ||= 'default'   
   render "help/#{id}"   
 end
 def back
   redirect_back(2)
 end
end
