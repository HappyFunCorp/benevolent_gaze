//= require jquery
//= require bootstrap
//= require_tree .

$(function() {
var es = new EventSource('/feed');
var new_people = [];
var current_people = [];

es.onmessage = function(e) {
  //console.log( "Got message", e )
}

es.addEventListener('message', function(e) {
  new_people = JSON.parse(e.data)
  rename_users(new_people);
  add_remove_workers(new_people);
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

var add_remove_workers = function(w){
  w.map(function(worker_data){
    var klass = worker_data.device_name.replace(/\./g, "");
    if($("."+klass).length > 0) {
      console.log("nobody new");
    } else {
      Welcome.move_logo_and_welcomes();
      current_people.push(worker_data);
      Worker.grab_worker();
      Worker.set_name(worker_data.name || sanitize_name(worker_data.device_name));
      Worker.add_class("."+klass);
      Worker.add_to_board();
      $('.newcomer h3').text(worker_data.name || sanitize_name(worker_data.device_name));
      $('.newcomer_avatar, .newcomer').show().removeClass('animated').removeClass('bounceOutUp').addClass('animated bounceInDown');
      $('.newcomer_avatar, .newcomer').one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(e) {
        $(this).removeClass('bounceInDown').addClass('bounceOutUp');
        Worker.redraw();
      })
    }
  });
  
  current_people = current_people.filter(function(worker){
    var last_seen_plus_five_mins = parseInt(worker.last_seen) + 150000;

    if (last_seen_plus_five_mins <= $.now()) {
      var klass = worker.device_name.replace(/\./g, "");
      Worker.remove_worker("."+klass);        
      $('.bounceOutDown').one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(e) {
        $(this).remove();
        Worker.redraw();
      });
    };
    return !(last_seen_plus_five_mins <= $.now());
  });
  
  current_people = current_people.map(function(cp){
    updated_person = cp;
     new_people.map(function(np){
       if (cp.device_name == np.device_name) {
         updated_person = np;
       }
     });
     return updated_person;
  });
};

var sanitize_name = function(name){
  var name_change = name.replace(/(s\-).*/, "");
      name_change = name_change.replace(/\-.*/, "");
      name_change = name_change.replace(/siP.*/, "");
      name_change = name_change.replace(/iM.*/, "");
      return name_change
};

var rename_users = function(user_names) {
  user_names.map(function(u){
    var name_klass = u.device_name.replace(/\./g, "");
    var $el = $('.'+name_klass);
    u_name = u.name || sanitize_name(u.device_name);
    $el.children('.tape').text(u_name);
    console.log(u);
    console.log("We are in rename users.");
    console.log(u.device_name);
    if ( typeof u.avatar == "string" ) {
      console.log("inside if");
      if ($el.hasClass("rotate90")) {
        console.log('already rotated');
      } else if ( u.device_name.match(/iPh/).length > 0 ) {
        $el.find(".avatar_container img").addClass('rotate90');
      }
      $el.find(".avatar_container img").attr('src', (u.avatar || "/images/visitor_art@1x.png"));
    }

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
