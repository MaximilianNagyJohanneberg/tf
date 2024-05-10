require "sqlite3"
require "bcrypt"
require 'sinatra/flash'

module Model
  # Connects to the database
  #
  # @return [SQLite3::Database] The database
  def connect_to_db(path)
      db = SQLite3::Database.new("db/databas.db")
      db.results_as_hash = true
      return db
  end

  # Registers a new user in the databse
  #
  # @param [String] username, The username of the user
  # @param [String] email, The email-adress of the user
  # @param [String] password, The choosen password of the user
  # @param [String] password_confirm, The password_confirm of the user
  #
  # return Boolean
  # * :message [String] the error message if an error occured
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

  # Retrieves user information from the database based on username
  #
  # @param [String] username, The username
  #
  # @return [Hash] User information as a hash
  def get_user_info(username)
    db = connect_to_db('db/databas.db')
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    return result
  end

  # Authenticates a password against a hashed password digest
  #
  # @param [String] password, The password to authenticate
  # @param [String] pwdigest, The hashed password digest
  #
  # @return [Boolean] Returns true if the password is authenticated, false otherwise
  def authenticate_password(password, pwdigest)
    return BCrypt::Password.new(pwdigest) == password
  end

  # Creates a new post in the database
  #
  # @param [Integer] user_id, The ID of the user creating the post
  # @param [String] title, The title of the post
  # @param [String] content, The content of the post
  def create_post(user_id, title, content)
    db = connect_to_db('db/databas.db')
    db.execute("INSERT INTO posts (user_id, title, content) VALUES (?, ?, ?)", user_id, title, content)
  end

  # Retrieves all posts from the database
  #
  # @return [Array] Array, containing all posts with associated user information
  def get_posts()
    db = connect_to_db('db/databas.db')
    results = db.execute("
      SELECT posts.*, users.username
      FROM posts
      JOIN users ON posts.user_id = users.id
    ")
    return results
  end

  # Deletes a post from the database
  #
  # @param [Integer] id, The ID of the post to delete
  # @param [Integer] user_id, The ID of the user attempting to delete the post
  #
  # @return [Boolean] Returns true if the post is deleted successfully, false otherwise
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

  # Updates a post in the database
  #
  # @param [Integer] id, The ID of the post to update
  # @param [String] title, The new title of the post
  # @param [String] content, The new content of the post
  def update_post(id, title, content)
    db = connect_to_db('db/databas.db')
    db.execute("UPDATE posts SET title = ?, content = ? WHERE id = ?", title, content, id)
  end

  # Retrieves a post from the database to be edited
  #
  # @param [Integer] id, The ID of the post to retrieve
  #
  # @return [Hash] Post information as a hash
  def get_post_for_edit(id)
    db = connect_to_db('db/databas.db')
    results = db.execute("SELECT * FROM posts WHERE id = ?", id).first
    return results
  end

  # Likes a post in the database
  #
  # @param [Integer] id, The ID of the post to like
  # @param [Integer] user_id, The ID of the user liking the post
  #
  # @return [String] Returns a message indicating the outcome of the like operation
  # * :message [String] the error message if an error occured
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

  # Unlikes a post in the database
  #
  # @param [Integer] id, The ID of the post to unlike
  # @param [Integer] user_id, The ID of the user unliking the post
  #
  # @return [String] Returns a message indicating the outcome of the unlike operation
  # * :message [String] the error message if an error occured
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


end