//= require jquery
//= require jquery.turbolinks
//= require jquery.ui.datepicker
//= require jquery.ui.autocomplete
//= require jquery.ui.effect.all
//= require jquery.validate
//= require file-validator
//= require m/multiStepForm
//= require megapix-image
//= require m/binaryajax
//= require m/exif
//= require kidslink
//= require kidsLinkRotation.js
//= require m/documents
//= require m/hospital_memberships
//= require m/profiles
//= require m/milestones
//= require m/dashboard
//= require m/global
//= require fastclick
//= require m/start
//= require m/iscroll
//= require turbolinks




// Turbo link related ---------------------------------------------------------------

$(document).on('click', '.viaTurbo',function () {
    Turbolinks.visit($(this).attr('data-url'));
});

// when clicks on kid profile in footer aread visit the page as turbo
$(document).on('click', '.footerChildListContainer div',function () {
    Turbolinks.visit($(this).attr('data-url'));
});


//show/hide loading indicator before changing the page via turbolinks --------------

$(document).on('page:fetch', function () {
    $('.loading_indicator').css('display', 'inline-block');
});

$(document).on('page:change', function() {
    // hide the loading indicator after page load
    $('.loading_indicator').css('display', 'none');
});