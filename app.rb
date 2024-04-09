require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

$login_attempts = 0

get('/') do
  slim(:register)
end
  
get('/showlogin') do
  slim(:login)
end

get('/strikes') do
  @login_attempts = $login_attempts  # Skicka antalet login_attempts till slim-filen
  slim(:strikes)
end
  
post('/login') do
  username = params[:username]
  password = params[:password]
  email = params[:email]
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  result = db.execute("SELECT * FROM users WHERE username = ?",username).first
  pwdigest = result["pwdigest"]
  id = result["id"]
  if BCrypt::Password.new(pwdigest) == password
    session[:id] = id
    session[:username] = username
    redirect('/posts')
  else
    $login_attempts += 1
    if $login_attempts == 3
      $login_attempts = 0 
    end
    redirect('/strikes')
  end
end

get('/showlogout') do 
  slim(:logout)
end

post("/users/new") do
 username = params[:username]
 password = params[:password]
 email = params[:email]
 password_confirm = params[:password_comfirm]

  if (password == password_confirm)
    pwdigest= BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/databas.db')
    db.execute("INSERT INTO users (username,pwdigest,email) VALUES(?,?,?)",username,pwdigest,email)
    redirect('/showlogin')
  else
    "lösenorden matchade inte"
    
  end
end

get('/posts') do 
  slim(:"posts/new")
end

post('/posts/new') do
  title = params[:title]
  content = params[:content]
  user_id = session[:id]
  db = SQLite3::Database.new("db/databas.db")
  db.execute("INSERT INTO posts (user_id, title, content) VALUES (?, ?, ?)", user_id, title, content)
  redirect('/posts/')
end


get('/posts/') do 
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
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
  db = SQLite3::Database.new("db/databas.db")
  user_post_id = db.execute("SELECT id FROM posts WHERE id = ? AND user_id = ?", id, user_id).first
  if user_post_id
    db.execute("DELETE FROM posts WHERE id = ?", id)
  else 
    halt "Du har inte rättighet att radera detta inlägg"
  end
  redirect('/posts')
end

post('/posts/:id/update') do
  id = params[:id].to_i
  title = params[:title]
  content = params[:content]
  db = SQLite3::Database.new("db/databas.db")
  db.execute("UPDATE posts SET title = ?, content = ? WHERE id = ?",title,content,id)
  redirect('/posts/')
end

get('/posts/:id/edit') do
  id = params[:id].to_i
  user_id = session[:id]
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  results = db.execute("SELECT * FROM posts WHERE id = ?",id).first
  user_post_id = db.execute("SELECT user_id FROM posts WHERE id = ? AND user_id = ?", id, user_id).first
  if user_post_id.nil? || user_id != user_post_id["user_id"]
    halt "Du har inte rättighet att ändra detta inlägg"
  else
    slim(:"/posts/edit", locals:{results:results})
  end
end




