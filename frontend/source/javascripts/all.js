//= require jquery
//= require bootstrap
//= require_tree .

$(function() {
var es = new EventSource('/feed');
var new_people = [];

es.onmessage = function(e) {
  //console.log( "Got message", e )
}

es.addEventListener('message', function(e) {
  new_people = JSON.parse(e.data)
  add_remove_workers(new_people);
  check_last_seen();  
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
  setup_and_add: function(worker_object) {
          var klass = worker_object.device_name.replace(/\./g, "");
          Worker.grab_worker();
          Worker.set_avatar(worker_object.avatar);
          Worker.set_name(worker_object);
          Worker.add_class("."+klass);
          Worker.add_to_board(worker_object);
        },
  grab_worker: function(){
                 w = $('.worker').first().clone();
               },
  set_image: function(string){
    $('img', w).attr('src', string);
  },
  set_name: function(worker_data){
              $('.tape', w ).text(sanitize_name( worker_data.name || worker_data.device_name));
              $(w).attr("data-name", (worker_data.name || worker_data.device_name));
              $(w).attr("data-devicename", worker_data.device_name);
            },
  set_avatar: function(avatar_url){
                $('.avatar_container img', w).attr('src', avatar_url || "/images/visitor_art@1x.png");
              },
  add_class: function(device_name){
               w.addClass(device_name.replace(/\./g, ""));
             },
  add_to_board: function(worker_data){
                  Welcome.move_logo_and_welcomes();
                  $(w).children('.pin_and_avatar_container').addClass("animated").addClass("swing" + (Math.floor(((Math.random() * 2) + 1))).toString());
                  $('.right_column .row').append( w );
                  $('.newcomer h3').text(worker_data.name || sanitize_name(worker_data.device_name));
                  $('.newcomer_avatar img').attr('src', worker_data.avatar || "/images/visitor_art@1x.png");
                  $('.newcomer_avatar, .newcomer').show().removeClass('animated').removeClass('bounceOutUp').addClass('animated bounceInDown');
                  $('.newcomer_avatar, .newcomer').one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(e) {
                    $(this).removeClass('bounceInDown').addClass('bounceOutUp');
                    Worker.redraw();
                  })
                },
  remove_worker: function(k) {
                   $( k ).addClass("animated bounceOutDown");
                   $('.bounceOutDown').one('webkitAnimationEnd mozAnimationEnd MSAnimationEnd oanimationend animationend', function(e) {
                     $(this).remove();
                     Worker.redraw();
                   });
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
    data_attribute = "[data-name='" + (worker_data.name || worker_data.device_name) + "']";
    data_attribute_device = "[data-name='" + worker_data.device_name + "']";
    $element = $(data_attribute);
    if ($element.length > 0) {
      $element.attr("data-lastseen", $.now());
      change_avatar(worker_data, data_attribute);
      data_attribute_worker = "[data-devicename='" + worker_data.device_name + "']";
      if ( $(data_attribute_worker).find(".tape").text() !== ( worker_data.name || sanitize_name(worker_data.device_name) ) ) {
        Worker.remove_worker(data_attribute_worker);
      }
    } else {
      Worker.setup_and_add(worker_data);
      if (worker_data.name) {
        Worker.remove_worker(data_attribute_device);
      }
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

var check_last_seen = function() {
  $('.worker').each(function(num, wk){
    console.log("not inside if yet");
    console.log(wk);
    console.log($(wk).attr('data-lastseen'));
    console.log($.now() - 5000);
    if (parseInt($(wk).attr('data-lastseen')) < ($.now() - 90000) && $(wk).find('.tape').text() !== "Ted" ) {
      console.log("inside if");
      Worker.remove_worker(wk);
    }
  })
}

var change_avatar = function(user_param, data_attribute){
  var element = $(data_attribute).find('.avatar_container img')
  if (typeof user_param.avatar == "string" && user_param.avatar != element.attr('src')) {
    $(data_attribute).find(".avatar_container img").attr('src',user_param.avatar);
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
  
};

});
