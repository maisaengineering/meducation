$('document').ready(function(){
    $('.mPreference .osSaveButton').click(function(e){
        kl = new KIDSLINK();
        if (kl.m_validatePreferences() === false) {
            e.preventDefault();
            return false;
        }else{
            $('form#mPrefernceForm').submit();
        }
    });
});

