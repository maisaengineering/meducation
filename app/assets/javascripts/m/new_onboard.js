/**
 * Created by maisapride786 on 9/4/14.
 */

var $error_messages  = [];
$(document).ready(function(){

    //$(".terms_popup").css("display","none"); 
    $("#terms").click(function(){
        $(".terms_popup").fadeIn(400).css("display","block");
        $("html, body").animate({
            scrollTop: 0
        }, 100);
        $("#closePopupBox").click(function(){
            $(".terms_popup").fadeOut(600);
        });
    });

    $('.stcError').hide();
    $('.loading_indicator').hide();
//    dowloadApp();
    $('#get_the_app').click(function(e){
        e.preventDefault();
        var from_org = false;
        error_count =0 ;
        $error_messages  = [];

        if($(this).hasClass('from_org')){
           var from_org = true;
           $('#invitation_org').val('1')
        }else{
           var from_org = false;
           $('#invitation_org').val('0')
        }


        $('#get_the_app').closest('form').find(':input').not('.not_required').each(function(){
            kl = new KIDSLINK();
            $this = $(this);
            kl_ErrorMessage="";
            if($.trim($this.val()).length<1){
                kl_ErrorMessage = "Oops! All fields are required"
            }else {
                switch ($this.attr('type')) {
                    case 'email':
                        if (KIDSLINK.prototype.validateEmail($this.val()) === false) {
                            kl_ErrorMessage = "Oops! invalid email";
                        }
                        break;
                    case 'password':
                        if ($.trim($this.val()).length < 6) {
                            kl_ErrorMessage = "Oops!  You need a stronger password";
                        } else if ($this.attr('id').indexOf("password_confirmation") > -1) {
                            if ($.trim($this.val()) != $.trim($this.parent().find("input#password").val())) {
                                kl_ErrorMessage = "Oops!  Passwords don't match";
                            }
                        }
                        break;
                    case 'tel':
                        var $id = $this.attr('id');
                        if($id.indexOf("phone_number")>-1){
                            var lengths =  $this.attr('lengths').split(',').map(function(i){ return parseInt($.trim(i))});
                            if($.inArray($this.val().length, lengths)<0 || !(parseRegex("/^\\d{"+ lengths[0]+"," +lengths[lengths.length -1]+"}$/")).test($this.val()) ){
                                kl_ErrorMessage = "Oops! Invalid phone number";
                            }
                        }

                       if($id.indexOf("phone_number_confirmation") > -1) {
                            if ($.trim($this.val()) != $.trim($this.closest('.mobileCodeRow').prev('.mobileCodeRow').find("input#phone_number").val())) {
                                kl_ErrorMessage = "Oops! phone number don't match";
                            }
                        }
                        break;
                    case 'checkbox':
                        if(!$this.is(':checked')){
                            kl_ErrorMessage = "Please accept the KidsLink Terms of Use";
                        }
                        break;
                    case 'text':
                        if ($this.attr('id').indexOf("zipcode") > -1) {
                            if($this.attr('format_regex')){
                                var regex = parseRegex($this.attr('format_regex'));
                                if(!regex.test($this.val())){
                                    kl_ErrorMessage = "Oops! Not a valid Postal code";
                                }
                            }
                        }
                }
            }
            if(kl_ErrorMessage!=''){
                setErrorMsg(kl_ErrorMessage);
                error_count++;
            }
        });
        if(error_count>0){
            alert($.unique($error_messages).reverse().join("\n"));
            return;
        }

        var myObject = new Object();
        myObject.fname = $('#fname').val();
        myObject.lname = $('#lname').val();
        myObject.email = $('#email').val();
        myObject.password = $('#password').val();
        myObject.password_confirmation = $('#password_confirmation').val();
        myObject.referral_code = $('#token').val();
        myObject.verified_phone_number = $('#country_code').val()+$('#phone_number').val();
//        myObject.phone_country_code = $('#country_code').val();
        myObject.address = {zipcode: $('#zipcode').val(), country: $("#country").val()};


        $.ajax({
            type: 'POST',
            url: '/api/users', // call to API to create user account with basic details
            dataType: "json",
            async:false,
            data:{
                command: "confirm_invitation",
                body: myObject
            },
            beforeSend: function(data){
                $('.loading_indicator').css('display', 'inline-block');
            },
            success: function(data){
                // redirect to download link
                if(new RegExp( '\\b' + data.message + '\\b', 'i').test('password incorrect')){
                    $('span#invitation_form').hide();
                    $('span#confirm_password').show();
                    $('.loading_indicator').css('display', 'none');
                }else{
                    // check if user registering via 'email' or 'sms' request
                    //Fix for if via email and opens in gmail mobile app
                    if($('#requested_from').val() == 'email'){
                        replace_with_download_app_link()
                    }else if(/(iPhone|iPod|iPad).*AppleWebKit(?!.*Safari)/i.test(navigator.userAgent)){
                        $('.gridContainer').html('<div class="mainContentBlock"><div class="rowOne">Congratulations!</div>'+
                            '<div class="invitationCode rowTwo">You’re now a<br>part of KidsLink.</div>'+
                            '<div><a href="kidslink://pop/utk='+data.body.utk+'"><img src="/assets/m/signIn.png" alt="" class="downloadIcon"></a></div>'+
                            '<div class="clear"></div></div>')
                    }else{
                        replace_with_download_app_link()
                    }
                }
            },
            error: function(jqXHR,exception){
                $('.loading_indicator').css('display', 'none');
                error_handling(jqXHR,exception);
            }
        })
        return false;
    })


    $('#btn_confirm_password').click(function(e){
        e.preventDefault();
        var myObject = new Object();
        myObject.email = $('#email').val();
        myObject.password = $('#current_password').val();
        myObject.phone_number = $('#country_code').val()+$('#phone_number').val();
//        myObject.phone_country_code = $('#country_code').val();
        myObject.referral_code = $('#token').val();
        $.ajax({
            type: 'POST',
            url: '/api/users', // call to API to create user account with basic details
            dataType: "json",
            async:false,
            data:{
                command: "validate_password",
                body: myObject
            },
            beforeSend: function(data){
                console.log(myObject);
                $('.loading_indicator').css('display', 'inline-block');
            },
            success: function(data){
                // redirect to download link
                console.log(data);
                if(/(iPhone|iPod|iPad).*AppleWebKit(?!.*Safari)/i.test(navigator.userAgent)){
                    $('.gridContainer').html('<div class="mainContentBlock"><div class="rowOne">Congratulations!</div>'+
                                            '<div class="invitationCode rowTwo">You’re now a<br>part of KidsLink.</div>'+
                                            '<div><a href="kidslink://pop/utk='+data.body.utk+'"><img src="/assets/m/signIn.png" alt="" class="downloadIcon"></a></div>'+
                                            '<div class="clear"></div></div>')

                    $('.loading_indicator').css('display', 'none');
                }else{
                    replace_with_download_app_link()
                }

            },
            error: function(jqXHR,exception){
                $('.loading_indicator').css('display', 'none');
                  alert("Oops! incorrect Password");
//                error_handling(jqXHR,exception);
            }
        })
        return false;
    })


    $('#forgot_password').click(function(e){

        e.preventDefault();
        var myObject = new Object();
        myObject.email = $('#email').val();
        myObject.referral_code = $('#token').val();

        $.ajax({
            type: 'POST',
            url: '/api/users', // call to API to create user account with basic details
            dataType: "json",
            async:false,
            data:{
                command: "forgot_password",
                body: myObject
            },
            beforeSend: function(data){
                $('.loading_indicator').css('display', 'inline-block');
            },
            success: function(data){
                $('.gridContainer').html('<div class="clear"></div>'+
                                         '<div class="mainContentBlock">'+
                                         '<div class="rowOne resetPadding">Thank you</div>'+
                                         '<div class="confirmPasswordStyle">'+
                                         '<p>You will receive an email with instructions about how to reset your password in a few minutes.</p>'+
                                         '</div><div class="clear"></div></div>' )
                $('.loading_indicator').css('display', 'none');
            },
            error: function(jqXHR,exception){
                $('.loading_indicator').css('display', 'none');
                alert("Oops! We don't have record of that email address");
            }
        })
        return false;
    })

    $(".btn_comment, .btn_accept_invitation, .klactimg").click(function(e){
        e.preventDefault();
        $('#invitation_form').show();
        $(this).closest('#klLatestActivity').hide();
    });

    $("#country").change(function(e){
        $this = $(this);
        $.ajax({
            url: '/m/countries_info',
            type: 'GET',
            dataType: 'json',
            data: {
                alpha2: $this.val()
            },
            success: function (country) {
                var $form = $this.closest('form');
                var $zip = $form.find('#zipcode');
                $this.val()=='US' ? $zip.removeClass('not_required') : $zip.addClass('not_required');
                ($this.val()=='US' && country.postcode_regex) ? $zip.attr('format_regex', country.postcode_regex) : $zip.removeAttr('format_regex');
                if($("#country_code").length>0){
                    $form.find('#phone_number, #phone_number_confirmation').attr('lengths', country.national_number_lengths);
                    if (!$form.find('.country_code').attr('noAutoEdit')) {
                        $form.find('.country_code').val("+" + country.country_code);
                    }
                }
            }
        });
    });

    $(".country_code").change(function(e){
        $(this).closest('form').find(".country_code").attr('noAutoEdit', true);
        $(this).closest('form').find(".country_code").val($(this).val());
    });
    if($("#country_code").length>0 && $("#country_code").val().length>1){ $(".country_code").change();}
    if($("#country").length>0){ $("#country").change(); }

//    $('*').click(function(e){
//        e.preventDefault();
//
//        e.stopPropagation();
//    })

    $('.formRow').click(function(e){
        e.stopPropagation();
    })

});

error_handling = function(jqXHR,exception){
    if (jqXHR.status === 406||jqXHR.status === 400 ){
        response = jQuery.parseJSON(jqXHR.responseText);
        add_error_messages_at_invitations(response.message);
    } else if (jqXHR.status === 0) {
        alert('Not connect.\n Verify Network.');
    } else if (jqXHR.status == 404) {
        alert('Requested page not found. [404]');
    } else if (jqXHR.status == 500) {
        alert('Internal Server Error [500].');
    } else if (exception === 'parsererror') {
        alert('Requested JSON parse failed.');
    } else if (exception === 'timeout') {
        alert('Time out error.');
    } else if (exception === 'abort') {
        alert('Ajax request aborted.');
    }

};

add_error_messages_at_invitations= function(response){
    var $response =  response.split(",");
    $error_messages = [];
    $.map($response, function(mess, i ) {
        $error_messages.push("Oops! "+ mess);
    });
    alert($.unique($error_messages).reverse().join("\n"));
};

setErrorMsg= function(error_message){
    $error_messages.push(error_message);
}

replace_with_download_app_link= function(){
    $('.gridContainer').html('<div class="mainContentBlock backgroundColorReset"><div class="rowOne">You’re almost there!</div>'+
        '<div class="invitationCode rowTwo">Next Step:<br>Download + sign in</div>'+
        '<div><a href="https://itunes.apple.com/us/app/kidslink/id880093467"><img src="/assets/downloadButton.png" alt=" " class="downloadIcon"></a></div>'+
        '<div class="clear"></div>'+
        '<div class="contentBlock">You will be transferred to the<br>App Store to download KidsLInk<br>for free.  Once downloaded, just<br>sign in with the email and<br>password you just created.</div></div>'+
        '<div class="clear"></div></div>')
}

parseRegex = function(regex){
return new RegExp(regex.replace("\\A", '^').replace("\\z", '$').slice(1,-1));
}