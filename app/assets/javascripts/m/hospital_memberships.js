$('document').ready(function(){
    kl = new KIDSLINK();
    kl.onKidFormLoad();
    $("#new_hospital_membership").kl_generateMultiStep();
    kl.generateKidsForm();
    $ ("#new_hospital_membership").submit(function(){
        $(this).submit(function() {
            return false;
        });
        return true;
    });

    $('#hm-submit-button').unbind("click").click(function(e){
        e.stopImmediatePropagation();

        $('fieldset .formErrorText').remove();
        if (kl.m_validateLastStep() === false) {

            e.preventDefault();
            $('html, body').animate({
                scrollTop: $('.formErrorText').offset().top-150
            }, 1000)
            return false;
        }else{
            $('.loading_indicator').css('display', 'inline-block');
            $("#new_hospital_membership").submit();
        }
    });

    $('.osfcInputZip').change(function(e){
        // get by zip code unless partner doesn't exists(from partner website url)
        var $this = $(this);
        $.ajax({
            method: 'get',
            url:'/m/hospital_memberships/top_hospitals',
            async: false,
            data:{zipcode:  $this.val()},
            success: function(data){

                $('.osPartnerButtonContainer').html(data);
                verify_onboardPartnerContainer();
            }
        });

    });
    $('.onboardWell .wellParChange a').click(function(e){
        e.preventDefault();
        $.ajax({
            method: 'get',
            url:'/m/hospital_memberships/change_wellness_partner',
            async: false,
            data:{zipcode: $('.osfcInputZip').val()},
            success: function(data){
//                $('.signUpPopUP').hide();
                $('body').append(data);
            }
        });
    });

});

verify_onboardPartnerContainer = function(){
    var $onboardPartner = $('.osPartnerButtonContainer').closest('#OnboardWellnessPartner');
    var $onboardPartnerButton =  $onboardPartner.find('.osPartnerButton');

    if($onboardPartnerButton.length == 1){
        if ( $onboardPartner.parent().is('fieldset') ) {
            if ( $onboardPartner.parent().parent().is("div") ) { $onboardPartner.parent().unwrap(); }
            $onboardPartner.unwrap();
        }
        $onboardPartner.hide();
        $("#hospital_id").val($onboardPartnerButton.attr('data-hospital-id'));
        if($onboardPartnerButton.attr('data-is-sponsor')=='true'){ $(".onboardWell .wellParChange").hide();}
        else{$(".onboardWell .wellParChange").show();}
        $(".onboardWell .wellParName").text($onboardPartnerButton.attr('data-hospital-name'));
    }else if( $onboardPartnerButton.length >1 && !$onboardPartner.parent().is('fieldset')){
        $onboardPartner.wrap("<fieldset></fieldset>");
        $onboardPartner.parent('fieldset').hide();
        $onboardPartner.show();
        $(".onboardWell .wellParChange").show();
    }
}

function add_more_kids(){
    var count = parseInt($(".preferred_kids input").last().attr('id'))+1;
    var placeholder =  $(".preferred_kids input").length+1;
    $(' .preferred_kids').append('<input type=text  placeholder= "child #' +placeholder+ '" name= "'+count+'" id="' +count+'"  onblur="kl_change_heading('+count+')"   class= "osfcInput requiredAny"> ');
}
//
function kl_change_heading(index){
    $('.head_'+index).text($("#"+index).val());
    $('#kids_' +index+ '_nickname').val($("#"+index).val());
}
//
function kl_verify_email(id){
   kl.checkEmailAvailability($("#"+id).val());
}
//















