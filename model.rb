require 'sqlite3'
require 'bcrypt'
module Model

    def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    db
    end

    def register(username, password, email)
    if (password == params[:password_comfirm])
        pwdigest= BCrypt::Password.create(password)
        db = connect_to_db('db/databas.db')
        db.execute("INSERT INTO users (username,pwdigest,email) VALUES(?,?,?)", username, pwdigest, email)
        redirect('/showlogin')
    else
        "Passwords did not match"
    end
    end

    def login(username, password)
    db = connect_to_db('db/databas.db')
    result = db.execute("SELECT * FROM users WHERE username = ?", username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
    if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        session[:username] = username
        redirect('/posts')
    else
        $login_attempts += 1
        if $login_attempts >= 3
        redirect('/strikes')
        end
        redirect('/strikes')
    end
    end

    def create_post(title, content, user_id)
    db = connect_to_db('db/databas.db')
    db.execute("INSERT INTO posts (user_id, title, content) VALUES (?, ?, ?)", user_id, title, content)
    redirect('/posts/')
    end

    def display_posts
    db = connect_to_db('db/databas.db')
    results = db.execute("
        SELECT posts.*, users.username
        FROM posts
        JOIN users ON posts.user_id = users.id
    ")
    slim(:"posts/index", locals: { results: results })
    end

    def delete_post(id, user_id)
    db = connect_to_db('db/databas.db')
    if user_id == 1 || db.execute("SELECT id FROM posts WHERE id = ? AND user_id = ?", id, user_id).first
        db.execute("DELETE FROM posts WHERE id = ?", id)
    else
        halt "You do not have permission to delete this post"
    end
    redirect('/posts')
    end

    def update_post(id, title, content)
    db = connect_to_db('db/databas.db')
    db.execute("UPDATE posts SET title = ?, content = ? WHERE id = ?", title, content, id)
    redirect('/posts/')
    end

    def edit_post(id, user_id)
    db = connect_to_db('db/databas.db')
    results = db.execute("SELECT * FROM posts WHERE id = ?", id).first
    user_post_id = db.execute("SELECT user_id FROM posts WHERE id = ? AND user_id = ?", id, user_id).first
    if user_id != 1 && (user_post_id.nil? || user_post_id["user_id"] != user_id)
        halt "You do not have permission to edit this post"
    else user_post_id.nil?
        slim(:"/posts/edit", locals:{results:results})
    end
    end

    def like_post(id, user_id)
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

    def unlike_post(id, user_id)
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
end