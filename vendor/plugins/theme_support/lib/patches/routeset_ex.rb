# Extends <tt>ActionController::Routing::RouteSet</tt> to automatically add the theme routes
class ActionController::Routing::RouteSet

  alias_method :__draw, :draw

  # Overrides the default <tt>RouteSet#draw</tt> to automatically
  # include the routes needed by the <tt>ThemeController</tt>
  def draw
    clear!
    # Creates the required routes for the <tt>ThemeController</tt>...
    # Added patch from D.J. Vogel that changes <tt>:filename</tt> to <tt>*filename</tt>... allowing sub-folders
    add_named_route 'theme_images', "/themes/:theme/images/*filename", :controller=>'theme', :action=>'images'
    add_named_route 'theme_stylesheets', "/themes/:theme/stylesheets/*filename", :controller=>'theme', :action=>'stylesheets'
    add_named_route 'theme_javascript', "/themes/:theme/javascript/*filename", :controller=>'theme', :action=>'javascript'
    add_route "/themes/*whatever", :controller=>'theme', :action=>'error'
    yield Mapper.new(self)
    named_routes.install
  end

end