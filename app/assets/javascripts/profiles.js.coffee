# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$("document").ready ->

  $('#profile_kids_type_birthdate1').datepicker
    changeMonth: true
    changeYear: true
    dateFormat: "mm/dd/yy"
    yearRange: "1900:2012"
