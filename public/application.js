$(document).ready(function(){
  $('#ajax').click(function(){
    $.getJSON("/game/init", function(data) {
      var dCards = data.dealer_cards;
      var pCards = data.player_cards;
      for (var i in dCards)  {
        $('#dealer-hand').append(Blackjack.img(dCards[i]));
      }
      for (var i in pCards) {
        $('#player-hand').append(Blackjack.img(pCards[i]));
      }
    });
  });
});


var Blackjack = {
  img: function(arr) {
    return $('<img />', {
      src: '/images/cards/' + arr[0] + '_' + arr[1] + '.jpg',
      class: 'img-polaroid img-rounded card',
      style: 'display:none'
    }).fadeIn('slow')

  },
  coverImg: function() {
    return "<img class='img-polaroid img-rounded card' src='/images/cards/cover.jpg' />"
  }
}