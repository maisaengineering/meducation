// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//= require jquery
//= require jquery_ujs
//= require jquery.validate
//= require profile_validation.js
//= require jquery.lazyload.min



//  This function is to apply the discount on payment page form
$(".apply_coupon").live("click", function(e) {
    e.preventDefault();
    $('.mathBlue').show();
    $('.paymentMathFigure .mathBlue .paymentMathKidsLink').show();
    $('.paymentMathFeeName .mathBlue').show();
    var amount = $("#annual_amount").val();
    var annual_fee = $("#annual_fee").val();
    var coupon_code = encodeURIComponent($("#coupon_code").val());
    var org_id = $("#org_id").val();
    return $.ajax({
        url: "/payments/update_discount_price",
        type: "GET",
        data: 'amount='+amount+"&annual_fee="+annual_fee+"&coupon_code="+coupon_code+"&org_id="+org_id,

        dataType: "script",
        complete: function(req) {

        }
    });
});

//This function is to disable the discount select box on admin section creating new coupons
$("#admin_coupon_coupon_type").live("change", function() {
    if($(this).val() == "Free Promotional")
    {
        $("#admin_coupon_discount").attr("disabled",true).val("100");
    }
    else
        {
        $("#admin_coupon_discount").attr("disabled",false).val("");
    }

});

//delays loading of images in long web pages for img with class 'lazy' only
function loadLazy(){
    $("img.lazy").lazyload();
}

$(document).ready(function(){
    loadLazy();
});