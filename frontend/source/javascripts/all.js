//= require jquery
//= require bootstrap
//= require_tree .

$(function() {
var es = new EventSource('/feed');
var arrivals = [];
var departures = [];
var changes = true;

es.onmessage = function(e) {
  console.log( "Got message", e )
}

es.addEventListener('message', function(e) {
  console.log(e.data);
  parsed_data = JSON.parse(e.data)

  if (parsed_data.name_update == true) {

    rename_users(parsed_data.user_names);

  } else {

    changes = parsed_data.changes;
    arrivals = parsed_data.arrivals
    departures = parsed_data.departures;
    add_people();

  }
}, false);

es.addEventListener('open', function(e) {
  console.log('Connection was opened.');
}, false);

es.addEventListener('error', function(e) {
  if (e.readyState == EventSource.CLOSED) {
    console.log('closed');
  }
}, false);


var w;

var Worker = {
  grab_worker: function(){
                 w = $('.worker').first().clone();
               },
  set_image: function(string){
    $('img', w).attr('src', string);
  },
  set_name: function(string){
              $('.tape', w ).text(string);
            },
  add_class: function(string){
               w.addClass(string.replace(/\./g, ""));
             },
  add_to_board: function(){
                  $(w).children('.pin_and_avatar_container').addClass("animated").addClass("swing" + (Math.floor(((Math.random() * 2) + 1))).toString());
                  $('.right_column .row').append( w );
                },
  remove_worker: function(k) {
                   $( k ).addClass("animated bounceOutDown");
                 },
  redraw: function() {
            var w = $('.worker').length;
            if ( w <= 6 ) {
              $('.board').removeClass('med small xsmall').addClass('large');
            } else if ( w <= 12 ) {
              $('.board').removeClass('small xsmall large').addClass('med');
            } else if ( w <= 24 ) {
              $('.board').removeClass('xsmall large med').addClass('small');
            } else {
              $('.board').removeClass('large med small').addClass('xsmall');
            }
          }
}

var add_people = function() {
  if ( changes == true ) {
    if (arrivals.length > 0 ) {
      arrivals.map(function(a){
        Worker.grab_worker();
        Worker.set_name(a.name);
        Worker.add_class(a.ip.replace(/\./g, ""));
        Worker.add_to_board();
        $('.newcomer h3').text(a.name);
        $('.newcomer_avatar, .newcomer').show().removeClass('animated').removeClass('bounceOutUp').addClass('animated bounceInDown');
        $('.newcomer_avatar, .newcomer').one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(e) {
          $(this).removeClass('bounceInDown').addClass('bounceOutUp');
          Worker.redraw();
        })
      });
      Welcome.move_logo_and_welcomes();
    }
    if (departures.length > 0 ) {
      departures.map(function(d){
        var klass = "." + d.ip.replace(/\./g, "");
        console.log("this is the class" + klass);
        Worker.remove_worker(klass);        
        $('.bounceOutDown').one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(e) {
          $(this).remove();
          Worker.redraw();
        });
        //$(klass).remove();
        console.log("in departures");
      });
    }
  }
}

var rename_users = function(user_names) {
  user_names.map(function(u){
    $('.'+u.ip.replace(/\./g, "")).children('.tape').text(u.name);
  });
}



var Welcome = {
  move_logo_and_welcomes: function() {
                 $('.logo').addClass("animated rubberBand");
                 $('.welcomes').addClass("animated tada");
                 $('.welcomes, .logo').one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(e) {
                    $(this).removeClass('animated').removeClass('tada').removeClass('rubberBand');
                  });
               }
  
}

});
