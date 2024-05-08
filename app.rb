require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'
require 'sinatra/flash'




enable :sessions


before '/posts/*' do
  unless session[:id]
    flash[:notice] = "Du måste vara inloggad för att komma åt den här sidan."
    redirect '/showlogin'
  end
end

$login_attempts = 0

 
get('/') do
  $login_attempts = 0
  session[:id] = nil
  slim(:register)
end
 
get('/showlogin') do
  session[:id] = nil
  slim(:login)
end


get('/error') do
  @login_attempts = $login_attempts
  flash[:notice] = "You have no more attempts left, wait a bit and try again!"
  slim(:"messages/error")
end
 
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



get('/posts/new') do
  slim(:"posts/new")
end


post('/posts') do
  title = params[:title]
  content = params[:content]
  user_id = session[:id]
  create_post(user_id, title, content)
  redirect('/posts/')
end


get('/posts/') do
  results = get_posts()
  slim(:"posts/index", locals: { results: results })
end



post('/posts/:id/delete') do
  id = params[:id].to_i
  user_id = session[:id]
  
  if user_id == 1 || delete_post(id, user_id)
    redirect('/posts/new')
  else
    halt "Du har inte rättighet att radera detta inlägg"
  end
end


post('/posts/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  content = params[:content]
  
  update_post(id, title, content)
  redirect('/posts/')
end

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


post('/posts/:id/like') do
  id = params[:id].to_i
  user_id = session[:id]
  notice = like_post(id, user_id)
  flash[:notice] = notice
  redirect('/posts/')
end

post('/posts/:id/unlike') do
  id = params[:id].to_i
  user_id = session[:id]
  notice = unlike_post(id, user_id)
  flash[:notice] = notice
  redirect('/posts/')
end
