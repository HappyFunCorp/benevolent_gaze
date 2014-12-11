//= require jquery
//= require bootstrap
//= require_tree .

$(function() {
var es = new EventSource('/feed');
var new_people = [];
var current_people = [];
var current_people_name_array = [];

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
  set_avatar: function(avatar_url){
                $('.avatar_container img', w).attr('src', avatar_url || "/images/visitor_art@1x.png");
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

  var temp_name_arr = [];

  w.map(function(worker_data){
    var klass = worker_data.device_name.replace(/\./g, "");
    name_presence = current_people_name_array.indexOf(worker_data.name);
    name_in_temp_arr = temp_name_arr.indexOf(worker_data.name);
    if($("."+klass).length > 0 || current_people_name_array.indexOf(worker_data.name) >= 0 || temp_name_arr.indexOf(worker_data.name) >= 0) {
      console.log("Nobody new.");
    } else {
      if (worker_data.name) {
        temp_name_arr.push(worker_data.name);
      }
      Welcome.move_logo_and_welcomes();
      current_people.push(worker_data);
      Worker.grab_worker();
      Worker.set_avatar(worker_data.avatar);
      Worker.set_name(worker_data.name || sanitize_name(worker_data.device_name));
      Worker.add_class("."+klass);
      Worker.add_to_board();
      $('.newcomer h3').text(worker_data.name || sanitize_name(worker_data.device_name));
      $('.newcomer_avatar img').attr('src', worker_data.avatar || "/images/visitor_art@1x.png");
      $('.newcomer_avatar, .newcomer').show().removeClass('animated').removeClass('bounceOutUp').addClass('animated bounceInDown');
      $('.newcomer_avatar, .newcomer').one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(e) {
        $(this).removeClass('bounceInDown').addClass('bounceOutUp');
        Worker.redraw();
      })
    }
  });
  
  current_people = current_people.filter(function(worker){
    var last_seen_plus_fifteen_mins = parseInt(worker.last_seen) + 900000;
    
    console.log(last_seen_plus_fifteen_mins);

    if (last_seen_plus_fifteen_mins <= $.now()) {
      var klass = worker.device_name.replace(/\./g, "");
      Worker.remove_worker("."+klass);        
      $('.bounceOutDown').one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(e) {
        $(this).remove();
        Worker.redraw();
      });
    };
    return !(last_seen_plus_fifteen_mins <= $.now());
  });
  
  current_people = current_people.map(function(cp){
    updated_person = cp;
     new_people.map(function(np){
       if (cp.device_name == np.device_name) {
         updated_person = np;
       }
       //if there is a name match this still updates the last_seen time on the other device so that it doesn't go stale.
       if (cp.name == np.name && cp.name != null && np.name != null) {
         cp.last_seen = np.last_seen;
         updated_person = cp;
       }
     });
     return updated_person;
  });

  current_people_name_array = current_people.map(function(cp){
    if (cp.name) {
      return cp.name;
    }
  });

};

var sanitize_name = function(name){
  var name_change = name.replace(/(s\-).*/, "");
      name_change = name_change.replace(/\-.*/, "");
      name_change = name_change.replace(/siP.*/, "");
      name_change = name_change.replace(/iP.*/, "");
      name_change = name_change.replace(/iM.*/, "");
      name_change = name_change.replace(/\..*/, "");
      if (name_change == "") {
        name_change = "ANONYMOUS";
      }
      return name_change
};

var rename_users = function(user_names) {
  user_names.map(function(u){
    var name_klass = u.device_name.replace(/\./g, "");
    var $el = $('.'+name_klass);
    u_name = u.name || sanitize_name(u.device_name);
    $el.children('.tape').text(u_name);
    change_avatar(u,name_klass);
  });
}

var change_avatar = function(user_param, klass){

  var element = $('.'+klass).find('.avatar_container img')
  if (typeof user_param.avatar == "string" && user_param.avatar != element.attr('src')) {
    //if (klass.match(/iP/) && !element.hasClass('rotate90')) {
      //$('.'+klass).find(".avatar_container img").addClass("rotate90");
    //}
    $('.'+klass).find(".avatar_container img").attr('src',user_param.avatar);
  }
};


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
