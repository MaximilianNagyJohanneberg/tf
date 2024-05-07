require "sqlite3"
require "bcrypt"
require 'sinatra/flash'

def connect_to_db(path)
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    return db
end

def register_user(username, email, password, password_confirm) 
    if email.empty? || username.empty? || password.empty? || password_confirm.empty?
      return "You must fill in all fields"
      
    elsif password != password_confirm
      return "Your password inputs were not identical"
  
    else
      db = connect_to_db('db/databas.db')
  
      if db.execute("SELECT id FROM users WHERE username = ?", username).any?
        return "This username is already in use"
      end
  
      if db.execute("SELECT id FROM users WHERE email = ?", email).any?
        return "This email is already in use"
      end
  
      pwdigest = BCrypt::Password.create(password)
      db.execute("INSERT INTO users (username,pwdigest,email) VALUES(?,?,?)", username, pwdigest, email)
      return true
    end
end

def login_user(username, email, password)
  db = connect_to_db('db/databas.db')
  result = db.execute("SELECT * FROM users WHERE username = ?", username).first
  
  if result.nil?
    $login_attempts += 1
    return { success: false }
  elsif result["email"] != email
    $login_attempts += 1
    return { success: false }
  else
    pwdigest = result["pwdigest"]
    id = result["id"]
    if BCrypt::Password.new(pwdigest) == password
      return { success: true, id: id, username: username }
    else
      $login_attempts += 1
      if $login_attempts >= 3
        return { success: false }
      else
        return { success: false }
      end
    end
  end
end
