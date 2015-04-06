$(document).ready(function(){

     kl_file_validator();

    $('#document_source').change(function(e){
        e.stopPropagation();
        e.preventDefault();
        if ( $('#document_source').val()!=""){
            $('#new_document').submit();
            $('#capture_type_of_category').hide();
//            $('#additional_information').show();
        }
    });

    $('#document_attachment').change(function(e){
        e.stopPropagation();
        e.preventDefault();
        if ( $('#document_attachment').val()!=""){
            $('#new_document').submit();
            $('#capture_type_of_category').hide();
            $('#capture_upload').show();
        }
    });

    if($('#capture_new_doc').val() === 'true'){
        // show profile section if user wants to capture from top-dashboard
        if($('#capture_doc_for').val() === 'Family') {
            $('#capture_select_profile').show();
        }else{
            $('#capture_type_of_category').show();
        }
    }

    $('#capture_new_document').click(function(e){
        e.preventDefault();
        if($('#capture_doc_for').val() === 'Family') {
            $('#capture_select_profile').show();
        }   else{
            $('#capture_type_of_category').show();
        }
    });

    $('.categoryRow').unbind("click").click(function(e){
        // collapse all docRows(sub categories of this category)
        e.preventDefault();
        $this= $(this) ;
        $.ajax({
            url: "/"+$this.attr('data-profile-id')+"/documents/child_node",
            cache: true,
            data: {category: $this.attr('data-category-id')} ,
            beforeSend: function(){
                $('.categoryRow').removeClass('categoryRowOn');
                $this.addClass('categoryRowOn');
            } ,
            success: function(html){
                $this.children('.docList').html(html);
                $this.children('.docList').slideToggle();
                tree_structure();
            }
        });
    }) ;


    $('#new_document').bind('ajax:before', function(){
        $('.form_loading').show();
//        $('#document_tags').val($('input.captureDocNewName').val());
    });
    
    $('#new_document').bind('ajax:complete', function(){
        $('#document_attachment').val('');
        $('#document_source').val('');
        $('#document_multi_upload').val(true);
        kl_file_validator();
        $('#document_attachment').change(function(e){
            e.stopPropagation();
            e.preventDefault();

            if ( $('#document_attachment').val()!=""){
                $('#new_document').submit();
                $('#capture_type_of_category').hide();
                $('#capture_upload').show();
            }
        });
    });

    document_uploads();

    // ----capture_upload
    $('#accept_and_save').unbind('click').click(function(e){
        e.preventDefault();
        $('#capture_upload').hide();
        $('#type_of_action').val('accept_and_save');
        $('#document_multi_upload').val(false);
        $('#additional_information').show();
    });
    // ----capture_upload
    $('#accept_and_capture').unbind('click').click(function(e){
        e.preventDefault();
        e.stopPropagation();
        $('#document_multi_upload').val(true);
        $('#type_of_action').val('accept_and_capture');

        $('#document_attachment').trigger('click');
    }) ;
    tree_structure();
    $('#demo1_selected_category').click();

});

function child_node(category, profile)
{
    $.ajax({
        url: "/"+profile+"/documents/child_node",
        cache:true,
        data: {category: category}
    }).done(function(html) {
            $('.'+category).html(html);

            tree_structure();
            document_uploads();
        });
}

function multiple_documents(category, profile)
{
    $.ajax({
        url: "/"+profile+"/documents/multiple_documents",
        method: 'GET',
        cache: true,
        data:{
            category: category,
            profile_id: profile
        }
    }).done(function(html) {
            $('.'+category).html(html);
            tree_structure();
            document_uploads();
            capture_select_profile();
        });
}

function tree_structure(){
    datePickerFormat();
    clickLink();
    $('.docRow').unbind("click").click(function(e){
        e.stopPropagation(); // for parent div unclickable
        e.preventDefault();
        var $this = $(this);
        if($this.attr('class').indexOf('getdoc')>0){
           $.ajax({
               url: "/"+$this.attr('data-document')+"/"+$this.attr('data-category')+"/document-buttons",
               success: function(data){
                  $this.find('.documentButtons').html(data);
                   tree_structure();

               }
           });
        }
        $('.docRow').removeClass('docRowOn');
        //then add rowOn class
        $(this).addClass('docRowOn');
        $(this).closest('.categoryRow').removeClass('categoryRowOn');
        $(this).children('.docList').slideToggle();
    });

    $(' .documentButton').click(function(e){
        e.stopPropagation();
    })  ;

    $('.document_edit').click(function(e){
        e.preventDefault();
        $this= $(this);
        $.ajax({
            url: $(this).children('a').attr('href'),
            success: function(html){
                $('#popUpAlertEvent').html(html).show();
            }
        });
    }) ;

    $('.cbCancel').unbind('click').click(function(e){
        e.preventDefault();
        $(this).closest('.popUpContainer').hide();
    });
}

function additional_information(){
    $('#bigSaveButton').click(function(e){
        e.stopPropagation();
        e.preventDefault();
        kl = new KIDSLINK();
        if($.trim($('.taken_on').val()).length>0 && kl.validateDate($('.taken_on').val())===true){
            $('#document_multi_upload').val(false);
            $('#document_org_provider').val($('#org_provider').val());
            $('#document_description').val($('#description').val());
            $('#document_taken_on').val($('#taken_on').val());
            $('#document_expiration_date').val($('#expiration_date').val());

            $('.'+$('#document_category_id').val()).hide();
            $('#additional_information').hide();

            $('.cubAccept').show();
            $('#type_of_action').val("");
            $('#new_document').submit();
        }else{
            $('.taken_on').parent().children('.captureAddMetaLabel').children('.errorFileField').remove();
            $('.taken_on').addClass('error');
            $('.taken_on').parent().children('.captureAddMetaLabel').append("<span class=errorFileField > ERROR: invalid date </span>");
        }
    });
}

function capture_select_profile(){
    $('.capture_profile_id').click(function(e){
        e.preventDefault();
        // assign the selected profile_id to forms profile_id
        $('input[id=document_profile_id]').val($(this).attr('id'));
        $('input[id=profile_id]').val($(this).attr('id'));
        // forward to next step ,i.e; show type of category to select
        $('#capture_select_profile').hide();
        $('#capture_type_of_category').show();
    });
}

function document_uploads(){

    // clicking capture new - documents vault on top category right click
    $('.capture_new_document_right').unbind('click').click(function(e){
        e.stopPropagation();
        e.preventDefault();
        $('#capture_type_of_category').show(); //show the category list
        var $this = $(this);
        // then pre populate children
        $.ajax({
            url: '/categories/'+$(this).attr('id')+'/ancestors' ,
            success: function(data){
                $('.captureCategory').removeClass('captureCategoryOn');
                $('#captureCategory-'+$this.attr('id')).toggleClass('captureCategoryOn');
                $("#selected_category").val($this.attr('id'));
                $('#captureDocTypeContainer').html(data);
            }
        });
    });

    $('.choose_document').unbind("click").click(function(e) {
        e.stopPropagation();
        e.preventDefault();
        $('.captureUploadBigNumber').text(0);
        $('.smallNumber').text(1);
        //set the category_id for choosen
        $('input[id=document_category_id]').val($(this).attr('id'));
        $('#document_attachment').trigger('click');
    });


    $('.choose_photograph').unbind("click").click(function(e) {
        e.stopPropagation();
        e.preventDefault();
        //set the category_id for choosen
        $('input[id=document_category_id]').val($(this).attr('id'));
        $('#document_source').trigger('click');
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

    $( "#tags" )
        // don't navigate away from the field on tab when selecting an item
        .bind( "keydown", function( event ) {
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
        })
        .keypress(function(e){

            if(e.which == 13) {
                e.preventDefault();
                e.stopPropagation();
                $(this).parent().children('.errorFileField ').remove();
                var user_tags =$.map($('#user_tags').val().split(", "), $.trim);
                var $this_tags =   $.unique($.grep($.map($(this).val().split(","), $.trim), function(tag){return tag!=""}));
                var new_tags = $.grep($this_tags, function(tag){ return tag!="" && $.inArray(tag, user_tags) == -1 ;});
                var old_tags = $.grep($this_tags, function(tag){ return tag!="" && $.inArray(tag, new_tags) == -1 ;});
                $('#document_category_id').val($("#selected_category").val());
                if((user_tags.length+new_tags.length)<=10){
                    if(($(this).attr('class').indexOf("edit_user_tag") <0)){
                        $(this).val( $.unique($this_tags));
                        $('#document_tags').val( $.unique($this_tags));
                        $('#document_attachment').trigger('click');
                    }else{
                        $('#edit_document_category_id').val($("#selected_category").val());
                        $(this).val( $.unique($this_tags));
                        $('#edit_document_tags').val($.unique($this_tags));
                        $('.category_display_name').text($.unique($this_tags));
                        $('#capture_to_change').hide();
                    }
                }else{
                    $(this).after("<span class=errorFileField  >Only 10 free tags are allowed. Please use your previous tags or contact kidslink for extra tags </span>");
                    $(this).val(old_tags);
                    $('#document_tags').val(old_tags);
                }
            }
        });

}

function edit_documents(){
    datePickerFormat();

    $('.submitPhotoId').click(function(e){
        e.preventDefault();
        kl = new KIDSLINK();
        if($.trim($('#document_edit_taken_on').val()).length>0 && kl.validateDate($('#document_edit_taken_on').val())===true){
            $('#edit_document').submit();
        }else{
            $('#document_edit_taken_on').parent().children('.captureAddMetaLabel').children('.errorFileField').remove();
            $('#document_edit_taken_on').addClass('error');
            $('#document_edit_taken_on').parent().children('.captureAddMetaLabel').append("<span class=errorFileField > ERROR: invalid date </span>");
        }
    });

    // ------------------ editing category ------------------------------------------------------
    $('.captureBottomButtons div.cbCancel').click(function(e){
        e.preventDefault();
        $('#popUpAlertEvent').html('').hide();  //or use fadeOut effect
    });

    $('.captureAddMetaChangeLink').click(function(e){
        e.preventDefault();
        var $this = $(this);
        $.ajax({
            url: '/categories/'+$(this).attr('id')+'/edit-category-children' ,
            success: function(data){
                $('#capture_to_change .captureCategory').removeClass('captureCategoryOn');
                $('#capture_to_change #captureCategory-'+$this.attr('id')).toggleClass('captureCategoryOn');
                $('#capture_to_change #captureDocTypeContainer').html(data);
//                $('.captureDocNewName').val( $('#edit_document_tags').val());
                $("#selected_category").val($this.attr('id'));
                $('#capture_to_change').show();
                clickLink();
            }
        });
    });

    $('#capture_to_change .cbCancel').unbind('click').click(function(e){
        e.preventDefault();
        $('#capture_to_change').hide();
    });

    $('#capture_to_change .captureCategoryTitle a').unbind('click').click(function(e){
        e.preventDefault();
        var $this = $(this);
        $.ajax({
            url: '/categories/'+$(this).attr('id')+'/edit-category-children' ,
            beforeSend: function(){
                // remove class captureCategoryOn for all elements
                $('.captureCategory').removeClass('captureCategoryOn');
                // add captureCategoryOn for clciked one
                $this.closest('.captureCategory').toggleClass('captureCategoryOn');
            },
            success: function(data){
                $('#capture_to_change #captureDocTypeContainer').html(data);
                $("#selected_category").val($this.attr('id'));
//                $('.captureDocNewName').val( $('#edit_document_tags').val());
            }
        });
    });
}


kl_file_validator = function(){
    $('#document_source, #photograph_source').fileValidator({
        onValidation: function(files){},
        onInvalid:    function(type, file){
            $('#document_source').val("");
            $('#photograph_source').val("");
            $('#capture_error_message').find('.captureTopTextError').html("<p><b>Oops. Are you sure that's an image?</b></p> Please select a JPEG or PNG file and try again.");
            $('#capture_error_message').show();
        },
        type: 'image',
        maxSize: '20m'
    });

    $('#document_attachment').fileValidator({
        onValidation: function(files){},
        onInvalid:    function(type, file){
            if(file.type=="application/pdf" && file.size <=2.097e+7 && $('#type_of_action').val()==""){
                $('.cubAccept').hide();
            }else{

                $('#document_attachment').val("");
                $('#capture_error_message').find('.captureTopTextError').html("<p><b>KidsLink is not able to capture this document.</b></p>The document repository is designed for archival documents, rather than versions you expect to edit. At this time, you can only upload images (JPEGs, PNGs) or Acrobat PDF files. If you are uploading a Word doc or Excel file, please save it as a PDF and try uploading it again.");
                $('#capture_error_message').show();
            }
        },
        type: 'image',
        maxSize: '20m'
    });
}