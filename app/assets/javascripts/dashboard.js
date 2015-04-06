function onDashboardLoad(){
  //  $('.birthdate').datepicker({changeYear: true, changeMonth: true, minDate:"-18y", yearRange:'1900:2100'});

    $.validator.addMethod("birthdate", function(value, element) {
        var re  = /^([1-9]|0[1-9]|1[012])[- \/\/.]([1-9]|0[1-9]|[12][0-9]|3[01])[- \/\/.](19|20)\d\d$/ ; ;
        if(re.test(value)){
            if($(element).attr('min-date')){
                return (Date.parse($(element).val()) >= Date.parse($(element).attr('min-date')))
            }else if($(element).attr('max-date')){
                return (Date.parse($(element).val()) <= Date.parse($(element).attr('max-date')))
            }
        }
        return re.test(value);
    } );

    $('#child_profile_edit').validate({
        onfocusout: false,
        onkeyup: false,
        onclick: false,
        onblur:false,
        errorElement: "span",
        errorPlacement: function(error, element) {
            var elementLabel =element.parent().children('.editProfileLabel');
            elementLabel.children('.error').remove();
            elementLabel.append(error);
        }
    });

    $('#child_profile_edit input').each(function () {
        $(this).rules('add', {
            messages: {
                required: "ERROR: can't be blank." ,
                birthdate: "ERROR: invalid date"
            }
        });
    });

//    ----------------  invite mom begin----------------------------------------------
    $('form#invite-mom').validate({
        onfocusout: false,
        onkeyup: false,
        onclick: false,
        onblur:false,
        errorElement: "span",
        errorPlacement: function(error, element) {
           error.insertAfter('form#invite-mom .inviteEmail');
        }
    });

    $('#dashCentralLinksInvite').click(function(e){
        e.preventDefault();
        $('form#invite-mom').children('span.error').remove();
        $('form#invite-mom .inviteEmail').removeClass('error');
        $('.popUpInvite').show();
    }) ;

    $('.ibInvite').unbind('click').click(function(e){
        e.preventDefault();
        $('form#invite-mom').submit();

    });

    $('.ibCancel').unbind('click').click(function(e){
        e.preventDefault();
        $('.popUpInvite').hide();
    });
    //    ----------------  invite mom end ----------------------------------------------

    on_click_manageable();

    $('.editProfileBigButtons .bigSaveButton').unbind('click').click(function(e){
        var parents_divs = $('.parent_forms .editProfileFieldContainerContacts');
        parents_divs.each(function(){
            var $this = $(this);
            if ( $this.children(":input.required[value!='']").length<1){
                $this.remove();
            }
        }) ;
        $('#child_profile_edit').submit();
    });

    $('.fixedCancelButton').unbind('click').click(function(){
        $(this).closest('#edit_child_profile_div').remove();
    });

    $('.profileEditButton, #profileEditButton').unbind('click').click(function(e){
        e.preventDefault();
        $('.bodyContainer').append('<div id=edit_child_profile_div></div>');
        $.ajax({
            url:'child-profile-edit',
            beforeSend: function(){ $('#form_loading').show();},
            success: function(html){
                $('#form_loading').hide();
                $('#edit_child_profile_div').html(html);
                onDashboardLoad();
            }
        });
    });

//    ----------------  preference page ----------------------------------------------

    $("form#edit_user").submit(function(){
        $('input').attr('readonly', true);
        $('a').unbind("click").click(function(e) {
            e.preventDefault();
            // or return false;
        });
    });

    $('#dashPreferencesFull .saveButton').click(function(e){
        if (kl.validatePreferences() === false) {
            e.preventDefault();
            return false;
        }else{
           $('form#edit_user').submit();
        }
    });
}

$(document).ready(function(){
    kl = new KIDSLINK();
    onDashboardLoad();
    $('.panelRSSSummary').find('a').attr('target', "_blank");
});

function add_new_parent_or_guardian(){
    var count= $('.parent_forms .editProfileFieldContainer').length;
    $.ajax({
        url: 'add-more-parents',
        data:{
            index: count
        },
        success: function(html){
            $('.parent_forms').append(html);
            on_click_manageable();
        }
    });
}

function on_click_manageable(){
    $(".parent_forms .editProfileFieldContainerContacts :input[type='checkbox']").click(function(){
        if($(this).is(':checked')){
            $(this).parent().siblings(":input[type='email']").addClass('required');
        }else{
            $(this).parent().siblings(":input[type='email']").removeClass('required');
        }
    });
}
