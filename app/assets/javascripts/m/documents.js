$('document').ready(function(){
    $('#document_source, #photograph_source').fileValidator({
        onValidation: function(files){},
        onInvalid:    function(type, file){
            $('#document_source').val("");
            $('.popUpMessage').find('.popUpMessageText').html("<p><b>Oops. Are you sure that's an image?</b></p> Please select a JPEG or PNG file and try again.");
            $('.popUpMessage').show();
            e.preventDefault();
        },
        type: 'image',
        maxSize: '20m'
    });
    $("#document_source").change(function(e){
        if ( $('#document_source').val()!="" ){
            $('.loading_indicator').css('display', 'inline-block');
            $("form#new_document").submit();
        }
    });

    $('.choose_photograph').unbind("click").click(function(e) {
        e.stopPropagation();
        e.preventDefault();
        $('.captureUploadBigNumber').text(0);
        $('.smallNumber').text(1);
        //set the category_id for choosen
        $('input[id=document_category_id]').val($(this).attr('id'));
        $('#add_info_category_name').html($(this).text());
        $('#document_source').trigger('click');
    });

    $('#document_attachment').fileValidator({
        onValidation: function(files){},
        onInvalid:    function(type, file){
            if(file.type=="application/pdf" && file.size <=2.097e+7 && $('#document_tag_name').length==0){
                $('.cubcButtonMore').hide();
            }else{
                $('#document_attachment').val("");
                $('.popUpMessage').find('.popUpMessageText').html("<p><b>KidsLink is not able to capture this document.</b></p>The document repository is designed for archival documents, rather than versions you expect to edit. At this time, you can only upload images (JPEGs, PNGs) or Acrobat PDF files. If you are uploading a Word doc or Excel file, please save it as a PDF and try uploading it again.");
                $('.popUpMessage').show();
                e.preventDefault();
            }
        },
        type: 'image',
        maxSize: '20m'
    });
    $('.cbCancel').unbind('click').click(function(){
        $(this).closest('.popUpContainer').hide();
    });

    $("#document_attachment").change(function(e){
        if ( $('#document_attachment').val()!="" ){
            $('.loading_indicator').css('display', 'inline-block');
            $("form#new_document").submit();
        }
    });

    if (  $("#user_tags").length!=0){
        tagging_documents();
    }


}) ;


function m_onClickUpload(category_id){
    $('#document_category_id').val(category_id);
    $('#document_attachment').trigger('click');
}

function m_UserTagonClickUpload(category_id, user_tag ){
    $('#document_category_id').val(category_id);
    $('#document_tags').val(user_tag);

    $('#document_attachment').trigger('click');
}

function m_onClickPhotographUpload(category_id){
    $('#document_category_id').val(category_id);
    $('#document_source').trigger('click');
}


function submit_document(){
    $( ".csbcButton").click(function(){
        if($('#document_taken_on').val()!="" ){
            $("form#new_document").submit();
        }else{
            $('#document_taken_on').prev('.cmfcDateLabel').children('.errorFileField').remove();
            $('#document_taken_on').prev('.cmfcDateLabel').append("<span class=errorFileField>Error: date required </span>")
        }
    });
}

function edit_document(){

    $( ".csbcButton.s").click(function(){
        if($('#document_taken_on').val()!="" ){
            $("form#edit_document").submit();
        }else{
            $('#document_taken_on').prev('.cmfcDateLabel').children('.errorFileField').remove();
            $('#document_taken_on').prev('.cmfcDateLabel').append("<span class=errorFileField>Error: date required </span>")
        }
    });
}



function tagging_documents(){

    var availableTags = $.map($('#user_tags').val().split(", "), $.trim);
    function split( val ) {
        return val.split( /,\s*/ );
    }

    function extractLast( term ) {
        return split( term ).pop();
    }

    $( "#tags" ).bind( "keydown", function( event ) {

            if ( event.keyCode === $.ui.keyCode.TAB &&
                $( this ).data( "ui-autocomplete" ).menu.active ) {
                event.preventDefault();
            }
        })
        .autocomplete({
            minLength: 0,
            source: function( request, response ) {
                // delegate back to autocomplete, but extract the last term
                response( $.ui.autocomplete.filter(
                    availableTags, extractLast( request.term ) ) );
            },
            focus: function() {
                // prevent value inserted on focus
                return false;
            },
            select: function( event, ui ) {
                var terms = split( this.value );
                // remove the current input
                terms.pop();
                // add the selected item
                terms.push( ui.item.value );
                // add placeholder to get the comma-and-space at the end
                terms.push( "" );
                this.value = terms.join( ", " );
                return false;
            },
            change: function(e, ui){


            }
        }).keydown(function(e){
            if(e.which == 13) {
                e.preventDefault();
                e.stopPropagation();
                $(this).parent().children('.errorFileField ').remove();
                var user_tags =$.map($('#user_tags').val().split(", "), $.trim);
                var $this_tags =   $.unique($.grep($.map($(this).val().split(","), $.trim), function(tag){return tag!=""}));
                var new_tags = $.grep($this_tags, function(tag){ return tag!="" && $.inArray(tag, user_tags) == -1 ;});
                var old_tags = $.grep($this_tags, function(tag){ return tag!="" && $.inArray(tag, new_tags) == -1 ;});
                if((user_tags.length+new_tags.length)<=10){
                    $(this).val( $.unique($this_tags));
                    $('#document_tags').val( $.unique($this_tags));
                    $('#document_category_id').val( $(this).attr('category_id'));
                    if(($(this).attr('class').indexOf("edit_user_tag") <0)){
                        $('#document_attachment').trigger('click');
                    }else{

                         window.location.href =$(this).attr('target_url')+"&tags="+$.unique($this_tags);
                    }
                }else{
                    $(this).after("<span class=errorFileField  >Only 10 free tags are allowed. Please use your previous tags or contact kidslink for extra tags </span>");
                    $(this).val(old_tags);
                    $('#document_tags').val(old_tags);
                }
            }
        });
 }
