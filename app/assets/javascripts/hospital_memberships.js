$(document).ready(function(){

    kl = new KIDSLINK();
    kl.onKidFormLoad();
    $("#new_hospital_membership").kl_generateMultiStep();
    kl.generateKidsForm();

    //-------to avoild multiple submittion--
    $ ("#new_hospital_membership").submit(function(){
        $(this).submit(function() {
            return false;
        });
        return true;
    });

    $('#hm-submit-button').unbind("click").click(function(e){
        e.stopImmediatePropagation();

        $('fieldset .formErrorText').remove();
        if (kl.validateLastStep() === false) {
            e.preventDefault();
            return false;
        }else{
            $("#new_hospital_membership").submit();
        }
    });

    $('.startBigMainButtonContainer').unbind("click").click(function(e){
        $('.signUpPopUP').show();
    });

    $('.onboardFields #zipcode').change(function(e){
        // get by zip code unless partner doesn't exists(from partner website url)
        var $this = $(this);
        $.ajax({
            method: 'get',
            url:'/hospital_memberships/top_hospitals',
            async: false,
            data:{zipcode:  $this.val()},
            success: function(data){
                $('.onboardPartnerContainer').html(data);
                verify_onboardPartnerContainer();
            }
        });
    });

    $('.onboardWell .wellParChange a').click(function(e){
        e.preventDefault();
        $.ajax({
            method: 'get',
            url:'/hospital_memberships/change_wellness_partner',
            async: false,
            data:{zipcode: $('.onboardFields #zipcode').val()},
            success: function(data){
                $('.signUpPopUP').hide();
                $('body').append(data);
            }
        });
    });
   $("#step0 #add_more_kids").click(function(e){
       e.preventDefault();
       var count = parseInt($(".preferred_kids input").last().attr('id'))+1;
       var placeholder =  $(".preferred_kids input").length+1;
       $('.preferred_kids').append('<input type=text  placeholder= "child # ' +placeholder + '" name= "'+count+'" id="' +count+'" class= "requiredAny"> ');
   });

    $("#step0 .preferred_kids input[type=text]").blur(function(e){
        e.preventDefault();
        index = $(this).attr('id');
        $('.head_'+index).text($("#"+index).val());
        $('#kids_' +index+ '_nickname').val($("#"+index).val());
    })

});

verify_onboardPartnerContainer = function(){
    var $onboardPartner = $('.onboardPartnerContainer').closest('.popUpOnboardPartner');
    var $onboardPartnerButton =  $onboardPartner.find('.onboardPartnerButton');
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
    }else if( $onboardPartnerButton.length > 1 && !$onboardPartner.parent().is('fieldset')){
        $onboardPartner.wrap("<fieldset></fieldset>");
        $onboardPartner.parent('fieldset').hide();
        $onboardPartner.show();
        $(".onboardWell .wellParChange").show();
    }
}

function kl_change_heading(index){
    $('.head_'+index).text($("#"+index).val());
    $('#kids_' +index+ '_nickname').val($("#"+index).val());
}

function kl_verify_email(id){
    kl.checkEmailAvailability($("#"+id).val());
}




