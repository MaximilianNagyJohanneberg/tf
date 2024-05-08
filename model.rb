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

def get_user_info(username)
  db = connect_to_db('db/databas.db')
  result = db.execute("SELECT * FROM users WHERE username = ?", username).first
  return result
end

def authenticate_password(password, pwdigest)
  return BCrypt::Password.new(pwdigest) == password
end

def create_post(user_id, title, content)
  db = connect_to_db('db/databas.db')
  db.execute("INSERT INTO posts (user_id, title, content) VALUES (?, ?, ?)", user_id, title, content)
end

def get_posts()
  db = connect_to_db('db/databas.db')
  results = db.execute("
    SELECT posts.*, users.username
    FROM posts
    JOIN users ON posts.user_id = users.id
  ")
  return results
end

def delete_post(id, user_id)
  db = connect_to_db('db/databas.db')
  post_owner = db.execute("SELECT id FROM posts WHERE id = ? AND user_id = ?", id, user_id).first

  if post_owner
    db.execute("DELETE FROM posts WHERE id = ?", id)
    return true
  else
    return false
  end
end


def update_post(id, title, content)
  db = connect_to_db('db/databas.db')
  db.execute("UPDATE posts SET title = ?, content = ? WHERE id = ?", title, content, id)
end

def get_post_for_edit(id)
  db = connect_to_db('db/databas.db')
  results = db.execute("SELECT * FROM posts WHERE id = ?", id).first
  return results
end

def like_post(id, user_id)
  db = connect_to_db('db/databas.db')
  already_liked = db.execute("SELECT id FROM likes WHERE user_id = ? AND post_id = ?", user_id, id).first

  if already_liked.nil?
    db.execute("INSERT INTO likes (user_id, post_id) VALUES (?, ?)", user_id, id)
    db.execute("UPDATE posts SET like_count = like_count + 1 WHERE id = ?", id)
    return "You liked the post!"
  else
    return "You already liked this post!"
  end
end

def unlike_post(id, user_id)
  db = connect_to_db('db/databas.db')
  already_liked = db.execute("SELECT id FROM likes WHERE user_id = ? AND post_id = ?", user_id, id).first

  if already_liked
    db.execute("DELETE FROM likes WHERE user_id = ? AND post_id = ?", user_id, id)
    db.execute("UPDATE posts SET like_count = like_count - 1 WHERE id = ?", id)
    return "You unliked the post!"
  else
    return "You haven't liked this post yet!"
  end
end
