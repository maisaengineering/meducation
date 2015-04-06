var emailAvail=0;
var error_count =0;

function KIDSLINK(){}

// -------Dynamically Generating Forms for kids details
KIDSLINK.prototype.generateKidsForm=function(){

    $('#step0 .bigNextButton, #step0 .osSaveButton').find('a').click(function(e){
        var preferred_kids = $(".preferred_kids :input[value!='']") ;
        var preffered_kids_forms =$(".preferred_kids_form fieldset");
        var blank_preffered_kids_fields = $('.preferred_kids :input[value=""]') ;
        var availFormsIds =new Array();
        var unknownFormIds =new Array();
        var blankPrefferedKidsFieldIds =new Array();
        var $a =  $(this).closest('.osSaveButton').length;

        preffered_kids_forms.each(function(i){
            $.merge(availFormsIds, $(this).attr('id'))
        });

        blank_preffered_kids_fields.each(function(){
            $.merge( blankPrefferedKidsFieldIds, $(this).attr('id'));
            if(preferred_kids.length>0){
                $(this).remove();
            }
        });

        unknownFormIds =$.grep(availFormsIds , function(id){
            return $.inArray(id, blankPrefferedKidsFieldIds) != -1 ;
        });

        for (var i = 0; i <  unknownFormIds.length; i++) {
            var fieldset = "fieldset[id ='" +unknownFormIds[i]+"']";
            $(fieldset).unwrap();
            $(fieldset).remove();
            $("#new_hospital_membership").kl_reGenerateMultiStep();
        }

        preferred_kids.each(function(i){
            var $this = $(this);
            var index = $this.attr('id');
            var url = '/hospital_memberships/kid_form' ;
            if($a>0){url = '/m/hospital_memberships/kid_form' ; }
            if($.inArray(index, availFormsIds)== -1 ){
                $.ajax({
                    url: url,
                    async: false,
                    data:{index: index},
                    success: function(data){
                        $('.preferred_kids_form').append(data);
                        kl_change_heading(index);
                        KIDSLINK.prototype.onKidFormLoad();

                    }
                });
            }
        });
        $("#new_hospital_membership").kl_reGenerateMultiStep();
        kl_move_to_next();
    }) ;

    function kl_move_to_next(){
        $('fieldset .formErrorText').remove();
        if( KIDSLINK.prototype.Validation(0, 5) === false){ return; }
        $('div[id^="step"]').css("display", "none");
        $('div[id="step1"]').css("display", "block");
    }
}

KIDSLINK.prototype.ValidateFields=function($this){
    var kl_ErrorMessage = '';
    var error_label =  $this.parent().children('.onboardLabel');
    if(error_label.length == 0){ error_label = $this.closest('.osfcFieldContainer').find('.osfcLabel');}

    error_label.children('.formErrorText').remove();
    $this.removeClass('error');

    if($.trim($this.val()).length<1){
        kl_ErrorMessage = "ERROR: can't be blank";
    }else{
        switch($this.attr('type')){
            case 'email':
                if(KIDSLINK.prototype.validateEmail($this.val()) === false){
                    kl_ErrorMessage = "ERROR: invalid email";
                }
                break;
            case 'password':
                if($this.attr('id').indexOf("current_password") >-1){
                    if($.trim($this.val()).length < 6 || !kl.evalCurrentPassword($this.val())){
                        kl_ErrorMessage = "ERROR: invalid Password";
                    }
                    break;
                }
                if($.trim($this.val()).length < 6 ){
                    kl_ErrorMessage = "ERROR: should be at least 6 characters";
                }else if($this.attr('id').indexOf("password_confirmation") >-1){
                    if($.trim($this.val()) != $.trim($this.closest('.psFields').find("input[name$='[password]']").val() || $this.closest('.psFields').find("input[name$='[info][password]']").val())){
                        kl_ErrorMessage = "ERROR:  password did not match";
                    }
                }

                break;
            case 'checkbox':
                if(!$this.is(':checked')){

                    $this.addClass('error');
                    KIDSLINK.prototype.setErrorMsg($this.parent(), "ERROR: need to accept");
                    error_count++;
                }
                break;
            case 'date':
                if($this.attr('min-date')){
                    if (Date.parse($this.val()) < Date.parse($this.attr('min-date'))){
                        kl_ErrorMessage = "ERROR: invalid date";
                    }
                }else if($this.attr('max-date')){
                    if (Date.parse($this.val()) > Date.parse($this.attr('max-date'))){
                        kl_ErrorMessage = "ERROR: invalid date";
                    }
                }
                 break;

            default:
                if($this.attr('class').indexOf("date") >-1){
                    if( KIDSLINK.prototype.validateDate($this.val()) === false){
                         kl_ErrorMessage = "ERROR: invalid format";
                    }else if($this.attr('min-date')){
                        if (Date.parse($this.val()) < Date.parse($this.attr('min-date'))){
                            kl_ErrorMessage = "ERROR: invalid date";
                        }
                    }else if($this.attr('max-date')){
                        if (Date.parse($this.val()) > Date.parse($this.attr('max-date'))){
                            kl_ErrorMessage = "ERROR: invalid date";
                        }
                    }
                }
        }
    }

    if(kl_ErrorMessage!=''){
        $this.addClass('error');

        KIDSLINK.prototype.setErrorMsg(error_label, kl_ErrorMessage);
        error_count++;
    }
}


KIDSLINK.prototype.ValidateEmailFormat=function($this){
    var kl_ErrorMessage = '';
    var error_label =  $this.parent().children('.onboardLabel');
    if(error_label.length == 0){ error_label = $this.closest('.osfcFieldContainer').find('.osfcLabel');}
    error_label.children('.formErrorText').remove();
    $this.removeClass('error');
    if(KIDSLINK.prototype.validateEmail($this.val()) === false){
        kl_ErrorMessage = "ERROR: invalid email format";
    }
    if(kl_ErrorMessage!=''){
        $this.addClass('error');

        KIDSLINK.prototype.setErrorMsg(error_label, kl_ErrorMessage);
        error_count++;
    }
}

KIDSLINK.prototype.validateLastStep= function(){
    var last = $(".onboardFields")[$(".onboardFields").length-1] ;
    error_count =0;
    $(last).find(".required").each(function(){
        KIDSLINK.prototype.ValidateFields($(this));
    });

    if($(":input.required_if[value!='']").length >0){
        $('.required_if').each(function(){
            KIDSLINK.prototype.ValidateFields($(this));
        });
    }
    if($(":input.validate_email_format[value!='']").length >0){
        $('.validate_email_format').each(function(){
            KIDSLINK.prototype.ValidateEmailFormat($(this));
        });
    }
    KIDSLINK.prototype.ValidateFields($(".signUpPopUP :input[type ='checkbox']"));
    if(error_count > 0){ return false; }
    return true;
}

KIDSLINK.prototype.m_validateLastStep= function(){

    error_count =0;
    $(":input.required").each(function(){
        KIDSLINK.prototype.ValidateFields($(this));
    });

    if($(":input.required_if[value!='']").length >0){
        $('.required_if').each(function(){
            KIDSLINK.prototype.ValidateFields($(this));
        });
    }
    KIDSLINK.prototype.ValidateFields($(":input[type ='checkbox']"));

    if(error_count > 0){ return false; }
    return true;
}

KIDSLINK.prototype.validatePreferences= function(){
    error_count =0;
    $(':input.required').each(function(){
        KIDSLINK.prototype.ValidateFields($(this));
    });

    if($(":input.current_password[value!='']").length >0){
        $(":input.current_password").each(function(){
            KIDSLINK.prototype.ValidateFields($(this));
        });
    }

    if($(":input[type='password'].required_if[value!='']").length >0){
        $(":input[type='password'].required_if, :input.current_password").each(function(){
            KIDSLINK.prototype.ValidateFields($(this));
        });
    }

    if($(":input[type='text'].required_if[value!='']").length >0 || $("select.required_if").val().length>0){
        $(":input[type='text'].required_if, select.required_if").each(function(){
            KIDSLINK.prototype.ValidateFields($(this));
        });
    }

    if(error_count > 0){ return false; }
    return true;
}

KIDSLINK.prototype.Validation= function(ser, count){
    if (ser < (count-1)) {

        var inputs_flds = $("#step"+ser+ " fieldset select.required, #step"+ser+ " fieldset input.required");
        var unique_flds = $("#step"+ser+ " fieldset select.unique, #step"+ser+ " fieldset input.unique");
        error_count =0;

        $("#step"+0 + " :input.requiredAny").each(function(){
            $(this).val($.trim($(this).val()));
        });

        if($("#step"+0 + " :input.requiredAny[value!='']").length <1){
            var error_label =  $("#step"+0 + " :input.requiredAny[value='']").eq(0).parent().prev('.onboardLabel');
            if(error_label.length == 0){ error_label = $("#step"+0 + " :input.requiredAny[value='']").eq(0).closest('.osfcFieldContainer').find('.osfcLabel');}
            KIDSLINK.prototype.setErrorMsg(error_label, "ERROR: at least one child information.");
            error_count++;
        }

        inputs_flds.each(function(){
            KIDSLINK.prototype.ValidateFields($(this));
            if( $(this).attr('type')== 'email' && emailAvail !=false){
                $(this).addClass('error')
                error_label =  $(this).parent().children('.onboardLabel');
                if(error_label.length == 0){ error_label = $(this).closest('.osfcFieldContainer').find('.osfcLabel');}
                KIDSLINK.prototype.setErrorMsg(error_label, "ERROR:email already exists");

                error_count++;
            }
        });

        unique_flds.each(function(){

            var $uniq_field = $(this);
            var $scope_field = $uniq_field.parent().find($(":input[name='"+$uniq_field.attr('scope') +"']"));
            var myObject = $.parseJSON("{\""+$uniq_field.attr('name')+"\":\""+$uniq_field.val()+"\",\""+$scope_field.attr('name')+"\":\""+$scope_field.val()+"\"}");
            var $current_kids_match = false;

            $uniq_field.closest('.preferred_kids_form').find('.unique').not($uniq_field).each(function(){

                $fname= $.trim($(this).val());
                $lname= $.trim($(this).parent().find($(":input[name='"+$(this).attr('scope') +"']")).val());

                if($.trim($uniq_field.val())===$fname && $.trim($scope_field.val())===$lname){

                    $uniq_field.addClass('error');
                    $scope_field.addClass('error');
                    error_label =  $uniq_field.parent().children('.onboardLabel');
                    if(error_label.length == 0){ error_label = $uniq_field.closest('.osfcFieldContainer').find('.osfcLabel');}
                    KIDSLINK.prototype.setErrorMsg(error_label, "ERROR: kid with First & Last Name already exists");

                    error_count++;
                    $current_kids_match=true;
//                    break;
                }
            });

            if(!$current_kids_match){
                $.ajax({
                    url:'/dashboard/evaluate-name',
                    data: myObject,
                    async: false,
                    dataType:'json',
                    success:function(){

                    },
                    success:function(){
                        $uniq_field.removeClass('error');
                        $scope_field.removeClass('error');
                    },
                    error:function(e){

                        $uniq_field.addClass('error');
                        $scope_field.addClass('error');
                        error_label =  $uniq_field.parent().children('.onboardLabel');
                        if(error_label.length == 0){ error_label = $uniq_field.closest('.osfcFieldContainer').find('.osfcLabel');}
                        KIDSLINK.prototype.setErrorMsg(error_label, "ERROR: kid with First & Last Name already exists");

                        error_count++;
                    }
                });
            }

        });

        if(error_count > 0 || emailAvail){ return false; }
        return true;
    }
}

KIDSLINK.prototype.onKidFormLoad=function(){
//    datePickerFormat();
    $('.birthdate').datepicker({changeYear: true, changeMonth: true, maxDate: "+0d", minDate:"-18y", yearRange:'1900:2100'});
    $('.obCancel').unbind("click").click(function(e){
        $('.signUpPopUP').hide();
    });

    $('.eula').unbind("click").click(function(e){
        $('.popUpOnboardEULA').show()
    });

    $('.obOk').unbind("click").click(function(e){
        $('.popUpOnboardEULA').hide();
    });

    $('.obPhoto').unbind("click").click(function(e){
        e.stopPropagation();
        e.preventDefault();
        var index= $(this).attr('data-index');
        $('#kids_' +index+ '_photograph').trigger('click');
    });

    $('.required').on('change', function(){
        error_count =0;
        KIDSLINK.prototype.ValidateFields($(this));
    });
    $('.unique').on('change', function(){
        error_count =0;
        var $scope_field = $(this).parent().find($(":input[name='"+$(this).attr('scope') +"']"));
        KIDSLINK.prototype.ValidateFields($scope_field);
    });


    $('.required_if').change(function(){
        error_count =0;
        if($.trim($(this).val()).length>0){
//            $('.required_if').each(function(){
//                KIDSLINK.prototype.ValidateFields($(this));
//            });
            KIDSLINK.prototype.ValidateFields($(this));
        }
    });
}

KIDSLINK.prototype.checkEmailAvailability= function(email){
    if(KIDSLINK.prototype.validateEmail(email) === false){
        emailAvail = true;
    } else{
        $.ajax({
            url:'/hospital_memberships/validate_email',
            data:{email: email },
            async: false,
            success: function(text){
                if(text == "1") {
                    emailAvail = true;
                } else{
                    emailAvail= false;
                }
            }
        });
    }
}

KIDSLINK.prototype.evalCurrentPassword= function(password){
    var validPassword=0;
    $.ajax({
        url:'/dashboard/evaluate-password',
        data:{password: password },
        async: false,
        success: function(text){
            if(text == "1") {
                validPassword= true;
            } else{
                validPassword= false;
            }
        }
    });
    return validPassword;
}

KIDSLINK.prototype.validateEmail= function(email) {
    var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
}

KIDSLINK.prototype.validateDate= function(date){
    var re  = /^([1-9]|0[1-9]|1[012])[- \/\/.]([1-9]|0[1-9]|[12][0-9]|3[01])[- \/\/.](19|20)\d\d$/ ;
    return re.test(date);
}

KIDSLINK.prototype.setErrorMsg= function(showErr, error_message){
    $(showErr).children('.formErrorText').remove();
    $(showErr).append("<span class=formErrorText >"+ error_message+"</span>");

}


//----------------------------- MOBILE--------------------------------------------

KIDSLINK.prototype.m_validatePreferences= function(){
    error_count =0;

    if($(":input.current_password[value!='']").length >0){
        $(":input.current_password").each(function(){
            KIDSLINK.prototype.ValidateFields($(this));
        });
    }

    if($(":input[type='password'].required_if[value!='']").length >0){
        $(":input[type='password'].required_if, :input.current_password").each(function(){
            KIDSLINK.prototype.ValidateFields($(this));
        });
    }

    if(error_count > 0){ return false; }
    return true;
}

KIDSLINK.prototype.m_validateFields=function($this){
    var kl_ErrorMessage = '';
    var error_label =  $this.parent();


    error_label.children('span.error').remove();
    $this.removeClass('error');

    if($.trim($this.val()).length<1){
        kl_ErrorMessage = "ERROR: can't be blank";
    }else{
        switch($this.attr('type')){
            case 'email':
                if(KIDSLINK.prototype.validateEmail($this.val()) === false){
                    kl_ErrorMessage = "ERROR: invalid email";
                }
                break;
            case 'password':
                if($this.attr('id').indexOf("current_password") >-1){
                    if($.trim($this.val()).length < 6 || !kl.m_evalCurrentPassword($this.val())){
                        kl_ErrorMessage = "ERROR: invalid Password";
                    }
                    break;
                }
                if($.trim($this.val()).length < 6 ){
                    kl_ErrorMessage = "ERROR: should be at least 6 characters";
                }else if($this.attr('id').indexOf("password_confirmation") >-1){
                    if($.trim($this.val()) != $.trim($("input[name$='[password]']").val() || $("input[name$='[info][password]']").val())){
                        kl_ErrorMessage = "ERROR:  password did not match";
                    }
                }

                break;
            case 'checkbox':
                if(!$this.is(':checked')){
                    kl_ErrorMessage = "ERROR: need to accept";
                }
                break;
            default:
                if($this.attr('class').indexOf("date") >-1 && KIDSLINK.prototype.validateDate($this.val()) === false){
                    kl_ErrorMessage = "ERROR: invalid format";
                }
        }
    }

    if(kl_ErrorMessage!=''){
        $this.addClass('error');
        error_label.append("<span class=error >"+ kl_ErrorMessage+"</span>");
        error_count++;
    }
}

KIDSLINK.prototype.m_evalCurrentPassword= function(password){
    var validPassword=0;
    $.ajax({
        url:'/m/evaluate-password',
        data:{password: password },
        async: false,
        success: function(text){
            if(text == "1") {
                validPassword= true;
            } else{
                validPassword= false;
            }
        }
    });
    return validPassword;
}




