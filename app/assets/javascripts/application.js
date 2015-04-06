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
//= require jquery.turbolinks
//= require jquery_ujs
//= require jquery-ui/datepicker
//= require jquery-ui/autocomplete
//= require jquery.validate
//= require kidslink
//= require multiStepForm
//= require fastclick
//= require file-validator
//= require jquery.remotipart
//= require megapix-image
//= require kidsLinkRotation
//= require alerts_and_events
//= require dashboard
//= require documents
//= require hospital_memberships
//= require milestones
//= require turbolinks


function datePickerFormat(){
    $('.date').datepicker({ changeYear: true, dateFormat: 'mm/dd/yy',  maxDate: "+0d", minDate:"-18y",  yearRange:'1900:2100'});

    $('.taken_on').datepicker({
            changeYear: true,
            changeMonth: true,
            altField: "#taken_on",
            altFormat: "yy-mm-dd",
            maxDate: "+0d",
            minDate:"-18y",
            yearRange:'1900:2100'
        }
    );
    $('.expiration_date').datepicker({
            changeYear: true,
            changeMonth: true,
            altField: "#expiration_date",
            altFormat: "yy-mm-dd" }
    );
    $('.edit_taken_on').datepicker({
            changeYear: true,
            changeMonth: true,
            altField: "#edit_taken_on_alt",
            altFormat: "yy-mm-dd" ,
            maxDate: "+0d",
            minDate:"-18y",
            yearRange:'1900:2100'}
    );
    $('.edit_expire_on').datepicker({
            changeYear: true,
            changeMonth: true,
            altField: "#edit_expire_on_alt",
            altFormat: "yy-mm-dd" }
    );
}
$('document').ready(function(){
    clickLink();
    addNeedsClick();
}) ;

function clickLink(){

    $('.clickLink').unbind('click').click(function(e){
        e.stopPropagation();
        $(this).find('a').click();
    });

    $('.clickLink').find('a').click(function(e){
        e.stopPropagation();
    });
}

window.addEventListener('load', function() { FastClick.attach(document.body); }, false)
function addNeedsClick(){
    $('.choose_document, .choose_photograph, .choose_document_at_user_tag, #change_photo_id').addClass('needsclick');
}



// Footer Animation
$(document).ready(function() {
    $(".new-menu li ul").hide();
    $('.currentClass ul').show();
    $('.new-menu li span').click(function (e){
        if (!$(this).parent('li').hasClass("currentClass")){
            // e.preventDefault();
            $('.currentClass ul').toggle("slide");
            $('.new-menu li').removeClass('currentClass');
            $(this).parent('li').addClass('currentClass');
            $('.currentClass ul').toggle("slide");
            $(this).siblings().first().children('li').children('a').removeClass('active');
            $(this).siblings().first().children('li').first().children('a').addClass('active');
        }
    });
    $('.new-menu li ul li a').click(function(e){
        // e.preventDefault();
        $('.new-menu li ul li a').removeClass('active');
        $(this).addClass('active');
    });
});

Turbolinks.pagesCached(0);
$(document).on('page:fetch', function () {
    // show loading indicator before changing the page via turbolinks
    // $("#turbolink_indicator").show();
   // $('.dashContainer').fadeOut('slow')
  $('.bodyContainer').animate( {"opacity": "0.4"}, "slow");

});


$(document).on('page:change', function() {
    // hide the loading indicator after page load
    // $("#turbolink_indicator").hide();
});


$(document).on('page:restore', function () {
    $('.bodyContainer').fadeIn('slow')
});


// render child profile via turbolinks
$(document).on('click', '#childPhotograph',function () {
    //window.location.href = $(this).attr('data-url');
    Turbolinks.visit($(this).attr('data-url'));
});






