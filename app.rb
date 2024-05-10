require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'
require 'sinatra/flash'


enable :sessions

include Model 

# Checks if session[:id] is equal to nil
#
before '/posts/*' do
  unless session[:id]
    flash[:notice] = "Du måste vara inloggad för att komma åt den här sidan."
    redirect '/showlogin'
  end
end

$login_attempts = 0

# Display register form
#
get('/') do
  $login_attempts = 0
  session[:id] = nil
  slim(:register)
end
 
#Display login form
#
get('/showlogin') do
  session[:id] = nil
  slim(:login)
end

# Display an error message
#
get('/error') do
  @login_attempts = $login_attempts
  flash[:notice] = "You have no more attempts left, wait a bit and try again!"
  slim(:"messages/error")
end
 
# Attempts login and updates the session
#
# @param [String] username, The username
# @param [String] password, The password
# @param [String] email, The email
#
# @see Model#get_user_info
# @see Model#authenticate_password
post('/login') do
  username = params[:username]
  password = params[:password]
  email = params[:email]

  result = get_user_info(username)
  
  if result.nil?
    $login_attempts += 1
    redirect('/error')
  elsif result["email"] != email
    $login_attempts += 1
    redirect('/error')
  else
    pwdigest = result["pwdigest"]
    id = result["id"]
    if authenticate_password(password, pwdigest)
      session[:id] = id
      session[:username] = username
      redirect('/posts/new')
    else
      $login_attempts += 1
      if $login_attempts >= 3
        redirect('/error')
      else
        redirect('/error')
      end
    end
  end
end

# Registers new user and redirects to '/showlogin'
#
# @param [String] username, The username
# @param [String] password, The password
# @param [String] email, The email
# 
# @see Model#register_user
post("/users") do
  username = params[:username]
  password = params[:password]
  email = params[:email]
  password_confirm = params[:password_confirm]
  
  registration_result = register_user(username, email, password, password_confirm)
  
  if registration_result == true
    redirect('/showlogin')
  else
    flash[:notice] = registration_result
    redirect('/')
  end
end

# Dispaly form for writing posts
#
get('/posts/new') do
  slim(:"posts/new")
end

# Creates post and redirects to '/posts/'
#
# @param [String] title, The title of the post
# @param [String] content, The content of the post
# 
# @see Model#create_post
post('/posts') do
  title = params[:title]
  content = params[:content]
  user_id = session[:id]
  create_post(user_id, title, content)
  redirect('/posts/')
end

# Display all posts written
# 
# @see Model#get_posts
get('/posts/') do
  results = get_posts()
  slim(:"posts/index", locals: { results: results })
end

# Deletes existing post and redirects to '/posts/new'
#
# @param [Integer] :id, The ID of the post
#
# @see Model#delete_post
post('/posts/:id/delete') do
  id = params[:id].to_i
  user_id = session[:id]
  
  if user_id == 1 || delete_post(id, user_id)
    redirect('/posts/new')
  else
    halt "Du har inte rättighet att radera detta inlägg"
  end
end

# Updates a existing post and redirects to '/posts/'
# 
# @param [Integer] :id, The ID of the post
# @param [String] title, The title of the post
# @param [String] content, The content of the post
# 
# @see Model#update_post
post('/posts/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  content = params[:content]
  
  update_post(id, title, content)
  redirect('/posts/')
end

# Displays a form for editing a existing post
#
# @param [Integer] :id, The ID of the post
#
# @see Model#get_pos_for_edit
get('/posts/:id/edit') do
  id = params[:id].to_i
  user_id = session[:id]
  
  results = get_post_for_edit(id)
  
  if user_id == 1 || (results && results["user_id"] == user_id)
    slim(:"/posts/edit", locals:{results:results})
  else
    halt "Du har inte rättighet att ändra detta inlägg"
  end
end

# Updates the number of likes for a post and redirects to '/posts/'
# 
# @param [Integer] :id, The ID of the post
#
# @see Model#like_post
post('/posts/:id/like') do
  id = params[:id].to_i
  user_id = session[:id]
  notice = like_post(id, user_id)
  flash[:notice] = notice
  redirect('/posts/')
end

# Updates the number of likes for a post and redirects to '/posts/'
#
# @param [Integer] :id, The ID of the post
#
# @see Model#unlike_post
post('/posts/:id/unlike') do
  id = params[:id].to_i
  user_id = session[:id]
  notice = unlike_post(id, user_id)
  flash[:notice] = notice
  redirect('/posts/')
end
