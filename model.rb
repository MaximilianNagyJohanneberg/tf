require "sqlite3"
require "bcrypt"
require 'sinatra/flash'

def connect_to_db(path)
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    return db
end

def register(username, email, password, password_confirm) 
    status = false
    if params[:email].empty? || params[:username].empty? || params[:password].empty? || params[:password_confirm].empty?
        return "You must fill in all fields"
        
    elsif password != password_confirm
        return "Your password inputs were not identicall"

    else
        db = connect_to_db('db/databas.db')
    
        if db.execute("SELECT id FROM users WHERE username = ?", username).any?
            return "This username is already in use"
        end
    
        if db.execute("SELECT id FROM users WHERE email = ?", email).any?
            return "This email is already in use"
        end
        return true
        pwdigest = BCrypt::Password.create(password)
        db.execute("INSERT INTO users (username,pwdigest,email) VALUES(?,?,?)", username, pwdigest, email)
        redirect('/showlogin')
    end
end
