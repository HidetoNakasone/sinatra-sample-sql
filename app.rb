
require "sinatra"
require "sinatra/reloader"
require "mysql2"
require "mysql2-cs-bind"

enable :sessions

# ======================

client = Mysql2::Client.new(
  :host => "localhost",
  :username => "root",
  :password => "root",
  :database => "hepdb"
)

# ======================

def is_login()
  if session[:user_id].nil?
    redirect '/login'
  end
end
# ======================

def time_con(time_info)
  if time_info > Time.now - 60
    # 1分 以内
    "#{(Time.now - time_info).floor}秒前"
  elsif time_info > Time.now - (60*60)
    # 1時間 以内
    "#{((Time.now - time_info)/(60)).floor}分前"
  elsif time_info > Time.now - (24*60*60)
    # 24時間 以内
    "#{((Time.now - time_info)/(60*60)).floor}時間前"
  elsif time_info > Time.now - (30*24*60*60)
    # 1月 以内
    "#{((Time.now - time_info)/(24*60*60)).floor}日前"
  elsif time_info > Time.now - (365*24*60*60)
    # 1年 以内
    "#{((Time.now - time_info)/(30*24*60*60)).floor}ヶ月前"
  else
    # 1年 以上
    "#{((Time.now - time_info)/(365*24*60*60)).floor}年前"
  end
end

# ======================

get '/' do
  redirect '/login'
end

# ======================

get '/login' do
  @page_info = session[:page_info]
  session[:page_info] = nil
  erb :login
end

# ======================

get '/form' do
  is_login()
  erb :form
end

# ======================

get '/logout' do
  session[:user_id] = nil
  redirect '/'
end

# ======================

get '/signup' do
  erb :signup
end

# ======================

post '/login' do

  res = client.xquery("SELECT * FROM users where user_name = ? and user_pass = ?;", params[:login_name], params[:login_pass]).first

  if res
    session[:user_id] = res['id']
    session[:user_name] = res['user_name']
    redirect '/form'
  else
    redirect '/login'
  end
end

# ======================

post '/signup' do

  res = client.xquery("SELECT * FROM users where user_name = ?;", params[:signup_name]).first

  if res
    session[:page_info] = "既存してるぜ。"
  else
    client.xquery("INSERT INTO users VALUES (NULL, ?, ?);", params[:signup_name], params[:signup_pass])
    session[:page_info] = "作ったよ。"
  end

  redirect '/login'
end

# ======================

post '/save' do

  if params[:upimg]
    up_img_name = params[:upimg][:filename]
    file = params[:upimg][:tempfile]
    File.open("./public/upimgs/" + up_img_name, 'wb') do |f|
      f.write(file.read)
    end
  else
    up_img_name = nil
  end

  client.xquery("INSERT INTO posts VALUES (NULL, ?, ?, ?, ?);", params[:sample_text], session[:user_name], up_img_name, DateTime.now)

  redirect '/show'
end

# ======================

get '/show' do
  is_login()
  @res = client.query("SELECT * FROM posts;")
  @res.each do |row|
    row['date_info_conv'] = time_con(row['date_info'])
  end

  erb :show
end
