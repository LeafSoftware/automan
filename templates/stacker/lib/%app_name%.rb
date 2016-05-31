require "<%= @app_name %>/version"
require "<%= @app_name %>/helpers"

module <%= app_name.split('_').map {|x| x.capitalize}.join('') %>
  # Your code goes here...
end
