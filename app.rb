require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sinatra/flash'
require_relative 'model'

enable :sessions

include Model

$login_attempts = 0

get('/') do
  slim(:register)
end

get('/showlogin') do
  slim(:login)
end

get('/strikes') do
  @login_attempts = $login_attempts
  flash[:notice] = "You have no more attempts left, wait a bit and try again!"
  slim(:"messages/strikes")
end

post('/login') do
  login(params[:username], params[:password])
end

post("/users/new") do
  register(params[:username], params[:password], params[:email])
end

get('/posts') do
  slim(:"posts/new")
end

post('/posts/new') do
  create_post(params[:title], params[:content], session[:id])
end

get('/posts/') do
  display_posts
end

post('/posts/:id/delete') do
  delete_post(params[:id], session[:id])
end

post('/posts/:id/update') do
  update_post(params[:id], params[:title], params[:content])
end

get('/posts/:id/edit') do
  edit_post(params[:id], session[:id])
end

post('/posts/:id/like') do
  like_post(params[:id], session[:id])
end

post('/posts/:id/unlike') do
  unlike_post(params[:id], session[:id])
end
