
// iOS7 footer issue fixed by hiding footer bar in form pages
ios7FooterBarHide = function(){
    $('input, select, textarea').each(function() {
        $(this).bind('focus', function() {
            $('.footerContainer').css("display","none")
        });
        $(this).bind('blur', function() {
            $('.footerContainer').css("display","block")
        });
    });

    $(":input[type='file']").click(function(e){
        $('.footerContainer').css("display","none")
    })
};