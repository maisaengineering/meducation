$('document').ready(function(){
    $.validator.addMethod("m_birthdate", function(value, element) {
        if($(element).attr('min-date')){
            return (Date.parse($(element).val()) >= Date.parse($(element).attr('min-date')))
        }else if($(element).attr('max-date')){
            return (Date.parse($(element).val()) <= Date.parse($(element).attr('max-date')))
        }else{
            return true;
        }
    } );

    $('#editChildProfile').validate({
        onfocusout: false,
        onkeyup: false,
        onclick: false,
        onblur:false,
        focusInvalid: false,
        errorElement: "span",
        errorPlacement: function(error, element) {
            var elementLabel =element.closest('.pefcFieldContainer').children('.pefcLabel');
            elementLabel.children('.error').remove();
            elementLabel.append(error);
        },
        invalidHandler: function(form, validator) {
            if (!validator.numberOfInvalids()){  return; }
            $('html, body').animate({
                scrollTop: $(validator.errorList[0].element).offset().top-150
            }, 1000);
        }
    });

    $('#editChildProfile input').each(function () {
        $(this).rules('add', {
            messages: {
                required: "ERROR: can't be blank" ,
                m_birthdate: "ERROR: invalid date"
            }
        });
    });

//   on_click_manageable();

    $('.peButtonContainer .peSaveButton').click(function(e){
        var parents_divs = $('.parent_forms .pefcFieldContainer');
        parents_divs.each(function(){
            var $this = $(this);
            if ( $this.find(":input.required[value!='']").length<1){
                $this.remove();
            }
        }) ;
        $('#editChildProfile').submit();
    });

});

function footerIos7Fix() {
    $('.footerContainer').addClass('footerContainer7Fix').attr('id', 'footerContainer');
}

function minviteButtonForm(){
    $('.minviteButton').click(function(){
        $("form#invite-mom").submit();
    });
}

function add_new_parent_or_guardian(){
    var count= $('.parent_forms .pefcFieldContainer').length;
    $.ajax({
        url: '/m/profiles/add-more-parents',
        data:{
            index: count
        },
        success: function(html){
            $('.parent_forms').append(html);
            on_click_manageable();

        }
    }).done(function(){
        ios7FooterBarHide();
    });
}

function on_click_manageable(){
    $(".parent_forms .pefcFieldContainer :input[type='checkbox']").click(function(){

        if($(this).is(':checked')){
            $(this).parent().siblings(":input[type='email']").addClass('required');
        }else{
            $(this).parent().siblings(":input[type='email']").removeClass('required');
        }
    });
}