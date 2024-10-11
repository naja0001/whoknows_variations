require 'sinatra'
require 'sqlite3'
require 'digest'

# Enable sessions
enable :sessions

# Set the secret key for session management
set :session_secret, 'da3259994058f90b0b08ab4650096c506825cd0a38fe40666c0f751e9ab21f5f'  # Replace with a strong, random string

# Set the database path to the existing database
set :database_path, '/tmp/whoknows.db'

# Connect to the database
def connect_db
  db = SQLite3::Database.new(settings.database_path)
  db.results_as_hash = true
  db
end

# Check if the database exists
def check_db_exists
  unless File.exist?(settings.database_path)
    puts "Database not found"
    exit(1)
  end
end

# Call the check before you connect
check_db_exists

# Password hashing function
def hash_password(password)
  Digest::SHA256.hexdigest(password)
end

# Password verification function
def verify_password(stored_password, input_password)
  stored_password == hash_password(input_password)
end

# Page Routes

# Home route (search page)
get '/' do
  q = params[:q]
  language = params[:language] || "en"  # Default language is English
  db = connect_db

  if q.nil? || q.empty?
    search_results = []
  else
    # Use parameterized queries to prevent SQL injection
    search_results = db.execute("SELECT * FROM pages WHERE language = ? AND content LIKE ?", language, "%#{q}%")
  end

  erb :search, locals: { search_results: search_results, query: q }
end

# About page route
get '/about' do
  erb :about
end

# Login page route
get '/login' do
  if session[:user_id]  # Check if the user is already logged in
    redirect '/'
  else
    erb :login
  end
end

# Registration page route
get '/register' do
  if session[:user_id]  # Check if the user is already logged in
    redirect '/'
  else
    erb :register
  end
end

# API Routes

# API endpoint for search
get '/api/search' do
  content_type :json  # Set the response content type to JSON
  q = params[:q]
  language = params[:language] || "en"

  db = connect_db

  if q.nil? || q.empty?
    search_results = []
  else
    # Use parameterized queries to prevent SQL injection
    search_results = db.execute("SELECT * FROM pages WHERE language = ? AND content LIKE ?", language, "%#{q}%")
  end

  { search_results: search_results }.to_json  # Convert the results to JSON
end

# API login route
post '/api/login' do
  content_type :json  # Set the response content type to JSON
  username = params[:username]
  password = params[:password]

  db = connect_db
  user = db.execute("SELECT * FROM users WHERE username = ?", username).first
  
  if user.nil?
    { error: 'Invalid username' }.to_json
  elsif !verify_password(user['password'], password)
    { error: 'Invalid password' }.to_json
  else
    session[:user_id] = user['id']
    { message: 'You were logged in' }.to_json
  end
end

# API register route
post '/api/register' do
  content_type :json  # Set the response content type to JSON
  username = params[:username]
  email = params[:email]
  password = params[:password]
  password2 = params[:password2]

  db = connect_db
  error = nil

  # Basic validation
  if username.empty?
    error = 'You have to enter a username'
  elsif email.empty? || !email.include?('@')
    error = 'You have to enter a valid email address'
  elsif password.empty?
    error = 'You have to enter a password'
  elsif password != password2
    error = 'The two passwords do not match'
  elsif db.execute("SELECT * FROM users WHERE username = ?", username).any?
    error = 'The username is already taken'
  end

  if error
    { error: error }.to_json
  else
    db.execute("INSERT INTO users (username, email, password) VALUES (?, ?, ?)", username, email, hash_password(password))
    { message: 'You were successfully registered and can log in now' }.to_json
  end
end

# API logout route
get '/api/logout' do
  session[:user_id] = nil
  { message: 'You were logged out' }.to_json
end
