
kl = new KIDSLINK();

// SignIn
function sign_in(){
    $('.signInButton').click(function(){
        $("form#new_user").submit();
    });
}

// Forget password
function reset_pass_submit(){
    $('.osSaveButton').click(function(){
        $("form#new_user").submit();
    });
}



