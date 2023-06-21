// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require_tree .
//= require_tree ./vendor

jQuery(function(){
  $(".container_img").imagezoomsl({
    zoomrange: [1, 3],
    zoomstart: 1.5,
    innerzoom: true,
    magnifierborder: "none"
  })
});

var __round = function(num){
  return Math.round(num * 100) / 100
}

var addItemToCart = function (){
  // btn info
  var btn = $(this);
  var price = parseFloat(btn.data('price'));
  var id = btn.data('id');
  var count = btn.data('count');
  var title = btn.data('title');
  // ------
  changeMiniCart(price, count);
  $.ajax({
    type   : 'get',
    url    : '/save_order',
    data   : {id: id, count: count, price: price, title: title},
    success: function (data) {
      if (!btn.closest(".rb_num").length){
        $(".popupCart").show();
      }else{
        var input = btn.closest(".rb_num").find("input");
        var curr_val = parseInt(input.val()) + parseInt(count);
        if (curr_val >= 0){
         input.val(curr_val);
         var parent_block = btn.closest(".rb_item");
         parent_block.find(".rb_total").text( parseFloat( parent_block.find(".rb_cost").text() ) * curr_val );
         updateTotalCartPrice();
       }
     }
   },
   error  : function () {
      // show_error('Ошибка', 3000);
    }
  });
}

var changeMiniCart = function(price, count){
  // block info
  var block_cart = $("#wpshop_minicart");
  var block_count = block_cart.find(".wpshop_mini_count .count");
  var block_sum = block_cart.find(".wpshop_mini_sum .sum");
  var curr_count = parseInt(block_count.text());
  var curr_sum = parseFloat(block_sum.text());
  // ------
  var next_count = parseInt(curr_count) + parseInt(count);
  if (next_count >= 0){
    block_cart.addClass('max_cart');
    block_count.text(next_count);

    block_sum.text(__round(curr_sum + (price*count) ));
  }
  if (next_count == 0){
    block_cart.removeClass('max_cart');
  }

  var cope_block = block_cart.clone();
  $(".floatFixedCard a div:first").remove();
  $(".floatFixedCard .cart_link").append(cope_block);


}

var removeItemInCart = function(){
  var btn = $(this);
  var id = btn.data('id');
  $.ajax({
    type   : 'get',
    url    : '/save_order',
    data   : {id: id, type: "remove"},
    success: function (data) {
      btn.closest(".rb_item").remove();
      updateTotalCartPrice();
    },
    error  : function () {
      // show_error('Ошибка', 3000);
    }
  });
}

var removeAllItemsInCart = function(){
  $.ajax({
    type   : 'get',
    url    : '/save_order',
    data   : {type: "clear"},
    success: function (data) {
      window.location.href = '/cart'
    },
    error  : function () {
      // show_error('Ошибка', 3000);
    }
  });
}

var buttonFormSubmit = function(){
  var btn = $(this);
  var type = btn.data("type");
  var ajax_url = '/order_request'
  var end_url = "/cart"
  if(type == "feedback"){
    var ajax_url = '/send_feedback'
    var end_url = "/"
  }
  var form = btn.closest("form");
  if (form.valid()){
    btn.hide();
    $.ajax({
      type   : 'get',
      url    : ajax_url,
      data   : form.serialize(),
      success: function (data) {
        form.hide();
        $(".popupOrderRequest").show();
        $(".popupOrderRequest .endOrderRequest").show();
        $("#modalBlackoutWindow").data("url", end_url);
      },
      error  : function () {
        // show_error('Ошибка', 3000);
      }
    });
  }else{
    btn.closest(".btn").find("span").show();
  }

}

var updateTotalCartPrice = function(){
  sum = 0;
  $("#wpshop_cart tbody .rb_total").each(function(n, e){ sum += parseFloat($(e).text()) });
  $("#wpshop_cart .all_price .rb_total strong").text(__round(sum));
}

var updateMobileSize = function(){
  if ($(window).width() <= 980) {
    $("#menu-wrap").removeClass("desktop").addClass("mobile");
    $("#menu-trigger").show();
  }else{
    $("#menu-wrap").removeClass("mobile").addClass("desktop");
  }
}

// var create_slider_ui= function(block, block_inp_min, block_inp_max, max_val, step){
//   block.slider({
//     min: 0,
//     max: max_val,
//     values: [block_inp_min.val(), block_inp_max.val()],
//     range: true,
//     step: step,
//     stop: function(event, ui) {
//       block_inp_min.val(block.slider("values", 0));
//       block_inp_max.val(block.slider("values", 1));
//     },
//     slide: function(event, ui){
//       block_inp_min.val(block.slider("values", 0));
//       block_inp_max.val(block.slider("values", 1));
//     },
//
//   });
// }

$(document).ready(function(){

  var snapValues = [
    $('input#min_vors_slide'),
    $('input#max_vors_slide')
  ];
  var snapSlider = $('#dlina_vorsa_slide');

  if (snapSlider.length){
    noUiSlider.create(snapSlider[0], {
      start: [parseInt(snapSlider.data("min")), parseInt(snapSlider.data("max"))],
      step: 1,
      connect: true,
      range: {
        'min': [0],
        'max': [100]
      }
    });

    snapSlider[0].noUiSlider.on('update', function (values, handle) {
      snapValues[handle].val(parseInt(values[handle]));
    });

    $.each(snapValues, function(n, e){
      e[0].addEventListener('change', function () {
        arr_v = $(e).attr("id") == "min_vors_slide" ? [$(e).val(), null] : [null, $(e).val()]
        snapSlider[0].noUiSlider.set(arr_v);
      });
    })

  }

  $(".sf-input-select").chosen({width: "100%"});

  $(document).on('click', '.mobile-link-top .icon_wrapp', function(){
    var block_menu = $(this).closest(".mobile-link-top").find('#mobilelink');
    if (block_menu.is(':visible')){
      block_menu.hide();
    }else{
      block_menu.show();
    }
  });

  $(document).on('click', '.menu-icon.icon-plus-sign-alt', function(){
    if ($("#menu-custom").hasClass("open_menu")){
      $("#menu-custom").hide();
    }else{
      $("#menu-custom").show();
    }
    $("#menu-custom").toggleClass("open_menu");


    var block_child = $("#menu-custom .menu-item-has-children");
    if (!block_child.find(".open-mobile-2.icon-plus").length){
      block_child.append("<span class='open-mobile-2 icon-plus'></span>");
      $(document).on('click', '.open-mobile-2.icon-plus', function(){
        var sub_menu = $(this).closest("li").find(".sub-menu:first");
        if (sub_menu.hasClass("open_menu")){
          sub_menu.hide();
        }else{
          sub_menu.show();
        }
        sub_menu.toggleClass("open_menu");
      });
    }

  });

  updateMobileSize();
  $(window).resize(function() {
    updateMobileSize();
  });

  $(document).on('click', '#menu-wrap .menu-icon.icon-plus-sign-alt', function(){

  })

  // create_slider_ui(
  //   $(".sf-meta-range-slider[data-sf-field-name='dlina_vorsa']"),
  //   $(".sf-input-range-number.sf-range-min.sf-input-number[name='dlina_vorsa[]']"),
  //   $(".sf-input-range-number.sf-range-max.sf-input-number[name='dlina_vorsa[]']"), 120, 1);
  //
  // create_slider_ui(
  //   $(".sf-meta-range-slider[data-sf-field-name='cost_1']"),
  //   $(".sf-input-range-number.sf-range-min.sf-input-number[name='cost_1[]']"),
  //   $(".sf-input-range-number.sf-range-max.sf-input-number[name='cost_1[]']"), 1600, 10);


  $('.grower').click(function() {
    $(this).toggleClass('bounce');
    $(this).parent('#sidebar li').find('> ul').slideToggle(600);
  });

  $(document).on('click', '.js_addItemToCart', addItemToCart);
  $(document).on('click', '.js_removeItemInCart', removeItemInCart);
  $(document).on('click', '.js_removeAllItemsInCart', removeAllItemsInCart);

  $(document).on('click', '.js_openFormOrderRequest', function(){
    $(".popupOrderRequest").show();
  });

  $(document).on('click', '#modalBlackoutWindow', function(){
    $(".popupOrderRequest").hide();
    if((typeof $(this).data('url') !== 'undefined') && $(this).data("url").length){
      window.location.href = $(this).data('url');
    }
  });

  $(document).on('click', '.js_buttonFormSubmit', buttonFormSubmit)
  $(document).on('click', '#wpshop_shadow_window', function(){
    $(".popupCart").hide();
    if((typeof $(this).data('url') !== 'undefined') && $(this).data("url").length){
      window.location.href = $(this).data('url');
    }
  });

  $('.js_changeGoodsCount').change(function(){
    $(this).closest(".line_1").find(".cart_button").data('count', $(this).val());
  });

  $(".validate").validate({
    rules: {
      'fname[first_name]': "required",
      'last_name': "required",
      'fname[patr_name]': "required",
      'title' : "required",
      'messages' : "required",
      'address[region]': "required",
      'address[city]': "required",
      'address[street]': "required",
      'address[index]': "required",

      email: {
        required: true,
        email: true
      },

      phone: {
        required: true,
        number: true,
        minlength: 11
      }
    },
    messages: {
      'fname[first_name]': false,
      'last_name': false,
      'fname[patr_name]': false,
      'title' : false,
      'messages' : false,
      'address[region]': false,
      'address[city]': false,
      'address[street]': false,
      'address[index]': false,

      email: {
        required: false,
        email: "Адрес должен быть вида name@domain.com"
      },
      phone: {
        required: false,
        minlength: "Телефон должен быть вида 79112223344",
        number: "Телефон должен быть вида 79112223344",
      }
    },
    focusInvalid: true,
    errorClass: "input_error"
  });

});

var showBlockFixedCart = function(){
  var originBlock = $(".carBoxOriginal");
  $(window).scroll(function() {
    if( ($("body").scrollTop()) > (originBlock.offset().top + 56) ){
      $(".floatFixedCard").show();
    }else{
      $(".floatFixedCard").hide();
    }
  });
}

var after_load_img = function(){
  $('img[data-src]').each(function(n, img){
    img.setAttribute('src', img.getAttribute('data-src'));
    img.onload = function(){
      img.removeAttribute('data-src');
    };
  });
}

$(window).load(function() {

  $('img').on('error', function(){
    $(this).attr('src', '/not_found.png');
  });

  after_load_img();

  showBlockFixedCart();
  $('#slideshow').nivoSlider({
    effect: 'fade',
    animSpeed: 600,
    pauseTime: 4500,
    controlNav: false,
    directionNav: true
  });

  if (($('#slideshow').length > 0)&&($("#banner_center").length == 0)) {
    $('#sidebar').addClass('absolut_slider');
  }

  $('#menu-wrap').css("display","block");
  $('#slideshow_wrapp').css("display","block");
  $("#galery_wrapp .thumb_img img").on('click', function(){
    var src = $(this).attr("src");
    $(this).closest("#galery_wrapp").find(".main_img img").attr('src', src);
  })
});