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
//= require jquery-ui/datepicker
//= require jquery.validate
//= require zeroclipboard
//= require organization_searches
//= require cocoon
//= require colpicker

$(document).ready(function(){
    $('.date').datepicker( {
        changeMonth: true,
       // changeYear: true,
      //  showButtonPanel: true,
        dateFormat: 'yy-mm-dd'});
// datepicker for AeDefinition occurring_on field
    $('.ae_occurring_on').datepicker({
            changeYear: true,
            changeMonth: true,
            altField: "#ae_occurring_on_alt",
            altFormat: "yy-mm-dd" }
    );
   /* $('.holiday_validity_start').datepicker({
            altField: "#holiday_validity_start_alt",
            altFormat: "yy-mm-dd" }
    );
    $('.holiday_validity_end').datepicker({
            altField: "#holiday_validity_end_alt",
            altFormat: "yy-mm-dd" }
    );*/
});

image_preview = function(input){
    if (input.files && input.files[0]) {
        var reader = new FileReader();
        reader.onload = function (e) {

            var img= new Image();
            img.src =  e.target.result;
            $(input).parent().append(img);
        }
        reader.readAsDataURL(input.files[0]);
    }
}