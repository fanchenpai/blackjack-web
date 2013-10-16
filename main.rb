require 'rubygems'
require 'sinatra'
require 'pry'

enable :sessions

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_POT_AMOUNT = 500

helpers do
  def calculate_total(arr=[])
    total = 0
    ace_count = 0
    arr.each do |card|
      if card[1].to_i.to_s == card[1]
        total += card[1].to_i
      elsif ['jack','queen','king'].include?(card[1])
        total += 10
      else # 'A'
        total += 11
        ace_count += 1
      end
    end
    until ace_count == 0 || total <= BLACKJACK_AMOUNT
      total -= 10
      ace_count -= 1
    end
    total
  end

  def deck
    ['clubs','diamonds','hearts','spades']
      .product(['2','3','4','5','6','7','8','9','10','jack','queen','king','ace'])
        .shuffle
  end

  def deal_one
    session[:deck] = deck if session[:deck].empty?
    session[:deck].pop
  end

  def card_face_image(card)
    "<img class='img-polaroid img-rounded card'
          src='/images/cards/#{card[0]}_#{card[1]}.jpg' />"
  end

  def card_back_image
    "<img class='img-polaroid img-rounded card' src='/images/cards/cover.jpg' />"
  end

  def player_total
    calculate_total(session[:player_hand])
  end

  def dealer_total
    calculate_total(session[:dealer_hand])
  end

  def round_init
    session[:round_count] += 1
    session[:dealer_hand] = []
    session[:player_hand] = []
    session[:dealer_turn] = false
    session[:round_ended] = false
    2.times {session[:dealer_hand] << deal_one }
    2.times {session[:player_hand] << deal_one }
  end

  def round_continue?
    if session[:dealer_turn]
      dealer_total < DEALER_MIN_HIT
    else
      player_total < BLACKJACK_AMOUNT
    end
  end

  def bet(n)
    session[:balance] -= n
    session[:bet] = n
  end

  def win
    session[:balance] += session[:bet] * 2
    session[:bet] = 0
  end

  def lose
    session[:bet] = 0
  end

  def tie
    session[:balance] += session[:bet]
    session[:bet] = 0
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
end

get "/form" do
  erb :form
end

post "/setname" do
  params[:username] = "Player" if params[:username].empty?
  session[:username] = params[:username]
  session[:deck] = deck
  redirect "/bet"
end

get "/bet" do
  session[:balance] ||= INITIAL_POT_AMOUNT
  session[:bet] = 0
  erb :bet
end

post "/setbet" do
  params[:bet] = 50 if params[:bet].to_i <= 0
  if params[:bet].to_i > session[:balance]
    @error = "Bet amount cannot be greater than what you have ($#{session[:balance]})"
    erb :bet
  else
    bet(params[:bet].to_i)
    round_init
    redirect "/game"
  end
end

get "/game" do
  unless round_continue?
    if session[:dealer_turn]
      if dealer_total > BLACKJACK_AMOUNT
        win
        @result = "Dealer busted. You win!"
      elsif dealer_total == BLACKJACK_AMOUNT
        lose
        @result = "Dealer hit blackjack. You lose."
      else # compare result
        if dealer_total > player_total
          lose
          @result = "Dealer win."
        elsif dealer_total < player_total
          win
          @result = "You win!"
        else
          tie
          @result = "It's a tie."
        end
      end
    else # player turn
      if player_total > BLACKJACK_AMOUNT
        lose
        @result = "Busted. You lose."
      else # blackjack!
        win
        @result = "Blackjack! You win!"
      end
    end
    @round_ended = true
  else
    @round_ended = false
  end
  erb :game
end

post "/hit" do
  if session[:dealer_turn]
    session[:dealer_hand] << deal_one
  else
    session[:player_hand] << deal_one
  end
  redirect "/game"
end

post "/stay" do
  session[:dealer_turn] = true
  redirect "/game"
end
