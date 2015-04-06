$(document).ready ->

  #ckicks on Alert Row toggole the row details
  $(".alertSummary div.alertMain").click (e) ->
    e.preventDefault()
    e.stopPropagation()
    $(".alertRow").not($(this).closest(".alertRow")).removeClass "alertRowOn" # remove Rowon if any of row are on
    $(".alertRow").not($(this).closest(".alertRow")).find(".alertDetails").hide(500);
    $(this).closest(".alertRow").toggleClass "alertRowOn"
    $(this).parent().siblings(".alertDetails").slideToggle()


  #I have done and Ignore ot Thanks button clciks
  $(".alertSummary .alertButtons .alertButton").click (e) ->
    e.stopPropagation()
    e.preventDefault()
    $this = $(this)
    $.ajax
      url: $this.children('a').attr('href')
      beforeSend: ->
        # show progress indicator (spinner) if need
      success: (data) ->
        # drop and remove completly
        ###$this.closest(".alertRow").hide "drop",
          direction: "down"
        , 700###
        $this.closest(".alertRow").fadeOut 400, ->
          $(this).remove()