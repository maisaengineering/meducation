// change temp photo of mst on the fly if milestone_image changes
function updateTempPhoto(input) {
    if (input.files && input.files[0]) {
        var reader = new FileReader();
        reader.onload = function (e) {
            if( parseInt($(":input[id$='rotate']").val())==0){
                $('#myCanvas').remove();
                $(input).parent().append($('<canvas/>',{  id: 'myCanvas' }));
            }
            kl_imageCompression(e.target.result, input, "");
//            mstPhoto.removeClass('mstPhotoTemp');
        }
        reader.readAsDataURL(input.files[0]);
    }
}

function kl_imageCompression(param, input, cross_origin_type){
    var $mstPhoto =$(input).parent().prev('.onboardFieldContainer').find('.onboardPhoto');
    var canvas=$(input).siblings("#myCanvas")[0];
    var $rotationEss = $(input).parent().prev('.onboardFieldContainer').find('.rotationEss');
    var img= new Image();
    if(cross_origin_type != ""){ img.crossOrigin = cross_origin_type;}
    img.onload=function(){
        var width = img.width;
        var height = img.height;
        var max_width = 500;
        var max_height = 500;

        if (width > height) {
            if (width > max_width) {
                //height *= max_width / width;
                height = Math.round(height *= max_width / width);
                width = max_width;
            }
        } else {
            if (height > max_height) {
                //width *= max_height / height;
                width = Math.round(width *= max_height / height);
                height = max_height;
            }
        }
        canvas.width = width;
        canvas.height = height;
        renderImageToCanvas(img, canvas, {width: width, height: height }, false);
        $mstPhoto.css('background-image',  "url("+canvas.toDataURL()+")");
        $rotationEss.show();
        $(input).siblings('#photoCanvasData').val(canvas.toDataURL('image/jpeg', 1));
        kl_addBackgroundImage(input);
    }
        img.src=param ;
}

function kl_addBackgroundImage(input){
    var canvas=$(input).siblings("#myCanvas")[0];
    var ctx=canvas.getContext("2d");
    var img= new Image();
    var angleInDegrees=parseInt($(input).parent().find(":input[id$='rotate']").val());
    var $imageOptions = $(input).parent().prev('.onboardFieldContainer').find('.onboardImageOptions');
    img.src=canvas.toDataURL();

    $imageOptions.find("div[class$='RotateCW']").click(function(){
        angleInDegrees+=90;
        kl_drawRotated(angleInDegrees, input);
    });

    $imageOptions.find("div[class$='RotateCCW']").click(function(){
        angleInDegrees-=90;
        kl_drawRotated(angleInDegrees, input);
    });

    function kl_drawRotated(degrees, input){
        var $mstPhoto =  $(input).parent().prev('.onboardFieldContainer').find('.onboardPhoto');
        ctx.clearRect(0,0,canvas.width,canvas.height);
        ctx.save();
        w = canvas.width;
        canvas.width =canvas.height;
        canvas.height =w;
        ctx.translate(canvas.width/2,canvas.height/2);
        ctx.rotate(degrees*Math.PI/180);
        ctx.drawImage(img,-img.width/2,-img.height/2);
        $mstPhoto.css('background-image',  "url("+canvas.toDataURL()+")");
        $(input).parent().find(":input[id$='rotate']").val(degrees);
//        $('#milestone_rotate').val(degrees);
        ctx.restore();
    }

}
