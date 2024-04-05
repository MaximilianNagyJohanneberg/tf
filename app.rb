require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'

enable :sessions

get('/') do
  slim(:register)
end
  
get('/showlogin') do
  slim(:login)
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
    session[:result] = result  # Lagra result i sessionen
    redirect('/todos')
  else
    "fel lösenord"
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

get('/todos') do 
  slim(:"todos/new")
end

post('/upload') do
  title = params[:title]
  content = params[:content]
  db = SQLite3::Database.new("db/databas.db")
  db.execute("INSERT INTO posts (title,content) VALUES (?,?)",title,content)
  redirect('/read')
end

get('/read') do 
  db = SQLite3::Database.new("db/databas.db")
  db.results_as_hash = true
  results = db.execute("SELECT * FROM posts")
  slim(:"read/index", locals: { results: results })
end

post('/read/:id/delete') do
  id = params[:id].to_i
  user_id = session[:id]
  db = SQLite3::Database.new("db/databas.db")
  # Kolla om användaren har rätt att ta bort inlägget
  result = db.execute("SELECT * FROM posts_and_user WHERE user_id = ? AND post_id = ?", user_id, id).first
  if result
    db.execute("DELETE FROM posts WHERE id = ?", id)
  else 
    "Du har inte rättighet att radera detta inlägg"
  end
  redirect('/read')
end
