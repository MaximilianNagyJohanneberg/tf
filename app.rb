require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
require 'sinatra/flash'


enable :sessions

before '/posts/*' do
  unless session[:id]
    flash[:notice] = "Du måste vara inloggad för att komma åt den här sidan."
    redirect '/showlogin'
  end
end


$login_attempts = 0

def connect_to_db(path)
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  return db
end
 
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
  username = params[:username]
  password = params[:password]
  email = params[:email]
  db = connect_to_db('db/databas.db')
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  pwdigest = result["pwdigest"]
  id = result["id"]
  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    session[:username] = username
    redirect('/posts/new')
  else
    $login_attempts += 1
    if $login_attempts >= 3
      redirect('/strikes')
    end
    redirect('/strikes')
  end
end


post("/users") do
  username = params[:username]
  password = params[:password]
  email = params[:email]
  password_confirm = params[:password_comfirm]

  if username.empty? || password.empty? || email.empty? || password_confirm.empty?
    return "Fyll i alla fält."
  elsif password != password_confirm
    return "Lösenorden matchade inte."
  else
    db = connect_to_db('db/databas.db')
  
    if db.execute("SELECT id FROM users WHERE username = ?", username).any?
      return "Användarnamnet är redan taget."
    end

    if db.execute("SELECT id FROM users WHERE email = ?", email).any?
      return "E-postadressen är redan registrerad."
    end

    pwdigest = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (username,pwdigest,email) VALUES(?,?,?)", username, pwdigest, email)
    redirect('/showlogin')
  end
end




get('/posts/new') do
  slim(:"posts/new")
end

post('/posts') do
  title = params[:title]
  content = params[:content]
  user_id = session[:id]
  db = connect_to_db('db/databas.db')
  db.execute("INSERT INTO posts (user_id, title, content) VALUES (?, ?, ?)", user_id, title, content)
  redirect('/posts/')
end

get('/posts/') do
  db = connect_to_db('db/databas.db')
  results = db.execute("
    SELECT posts.*, users.username
    FROM posts
    JOIN users ON posts.user_id = users.id
  ")
  slim(:"posts/index", locals: { results: results })
end

post('/posts/:id/delete') do
  id = params[:id].to_i
  user_id = session[:id]
  db = connect_to_db('db/databas.db')
  if user_id == 1 || db.execute("SELECT id FROM posts WHERE id = ? AND user_id = ?", id, user_id).first
    db.execute("DELETE FROM posts WHERE id = ?", id)
  else
    halt "Du har inte rättighet att radera detta inlägg"
  end
  redirect('/posts/new')
end


post('/posts/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  content = params[:content]
  db = connect_to_db('db/databas.db')
  db.execute("UPDATE posts SET title = ?, content = ? WHERE id = ?",title,content,id)
  redirect('/posts/')
end


get('/posts/:id/edit') do
  id = params[:id].to_i
  user_id = session[:id]
  db = connect_to_db('db/databas.db')
  results = db.execute("SELECT * FROM posts WHERE id = ?",id).first
  user_post_id = db.execute("SELECT user_id FROM posts WHERE id = ? AND user_id = ?", id, user_id).first
  if user_id != 1 && (user_post_id.nil? || user_post_id["user_id"] != user_id)
    halt "Du har inte rättighet att ändra detta inlägg"
  else user_post_id.nil?
    slim(:"/posts/edit", locals:{results:results})
  end
end


post('/posts/:id/like') do
  id = params[:id].to_i
  user_id = session[:id]
  db = connect_to_db('db/databas.db')
  already_liked = db.execute("SELECT id FROM likes WHERE user_id = ? AND post_id = ?", user_id, id).first
 
  if already_liked.nil?
    db.execute("INSERT INTO likes (user_id, post_id) VALUES (?, ?)", user_id, id)
    db.execute("UPDATE posts SET like_count = like_count + 1 WHERE id = ?", id)
    flash[:notice] = "You liked the post!"
  else
    flash[:notice] = "You already liked this post!"
  end
 
  redirect('/posts/')
end


post('/posts/:id/unlike') do
  id = params[:id].to_i
  user_id = session[:id]
  db = connect_to_db('db/databas.db')
  already_liked = db.execute("SELECT id FROM likes WHERE user_id = ? AND post_id = ?", user_id, id).first
 
  if already_liked
    db.execute("DELETE FROM likes WHERE user_id = ? AND post_id = ?", user_id, id)
    db.execute("UPDATE posts SET like_count = like_count - 1 WHERE id = ?", id)
    flash[:notice] = "You unliked the post!"
  else
    flash[:notice] = "You haven't liked this post yet!"
  end
 
  redirect('/posts/')
end