require 'rubygems'
require 'sinatra'
require 'pry'

enable :sessions

helpers do
  def total

  end

  def deck
    ['clubs','diamonds','hearts','spades']
      .product(['2','3','4','5','6','7','8','9','10','jack','queen','king','ace'])
        .shuffle
  end
end

get "/restart" do
  session.clear
  redirect "/"
end

get "/" do
  session[:round_count] ||= 1
  if session.has_key?(:username)
    redirect "/bet"
  else
    redirect "/form"
  end
  #erb :home
end

get "/form" do
  erb :form
end

post "/setname" do
  session[:username] = params[:username]
  redirect "/"
end

get "/bet" do
  session[:balance] ||= 500
  erb :bet
end

post "/setbet" do
  if params[:bet].to_i > session[:balance]
    @error = "Bet amount cannot be greater than what you have ($#{session[:balance]})"
    erb :bet
  else
    session[:balance] -= params[:bet].to_i
    session[:round_count] += 1
    session[:deck] = deck()
    session[:dealer_hand] = []
    session[:player_hand] = []
    2.times {session[:dealer_hand] << session[:deck].pop }
    2.times {session[:player_hand] << session[:deck].pop }
    redirect "/game"
  end
end

get "/game" do
  erb :game
end