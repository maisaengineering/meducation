(function($) {
    $.fn.kl_generateMultiStep = function(options) {
        var element = this;
        var steps = $(element).find("fieldset");
        var count = steps.size();
        steps.each(function(i) {
//            $(this).addClass('step');
            $(this).wrap("<div id='step" + i + "'></div>");

            $("#step"+i+" .osSaveButton ").prepend("<span id='step" + i + "commands'></span>");
            $("#step"+i+" .obPrevious").prepend("<span id='step" + i + "commands'></span>");

            $("#step"+i+" input[type='file']").fileValidator({
                onValidation: function(files){
                    if($("#step"+i+" input[type='file']").val()!=""){
                        $("#step"+i+" .obPhoto").parent().find('.errorFileField').remove() ;
                    }
                },
                onInvalid:    function(type, file){
                    $("#step"+i+" input[type='file']").val(null);
                    $("#step"+i+" .obPhoto").siblings('.osfcFieldText').html("<span class='errorFileField'>Warning : Invalid Image Format</span>");
                },
                type: 'image',
                maxSize: '20m'
            });

//           Identity photo "uploaded" indicator on mobile

            $("#step"+i+" input[type='file']").change(function(){
                if (this.files && this.files[0]) {
                    $("#step"+i+" .obPhoto").parent().find('.errorFileField').remove() ;
                    $("#step"+i+" .obPhoto").siblings('.osfcFieldText').text("Photo selected" );
                    if ($("#step"+i+" :input.required[value='']").length <1){
                        $("#step" +i+ "Next").trigger('click');
                    }
                }
            });
//           end   Identity photo "uploaded" indicator on mobile

            if (i == 0) {
                createNextButton(i);
            }
            else if (i == count - 1) {
                $("#step" + i).hide();
                createPrevButton(i);
            }
            else {
                $("#step" + i).hide();
                createPrevButton(i);
                createNextButton(i);
            }
        });

        function createPrevButton(i) {
            var stepName = "step" + i;
            var prelabeltext =  "back" ;
            var preStepName = "step"+(i-1);
            var subtext ="" ;
            if(i==1){prelabeltext = "First step";}
            else if(i+1  == count && $("#"+preStepName+" #hospital_id").length>0){ prelabeltext = "wellness";   }
            else{ prelabeltext = $("#"+preStepName+" .nickname").val();}
            $(".obPrevious #" + stepName + "commands").append("<a href='#' id='" + stepName + "Prev' class='prev'>"+prelabeltext+"</a>");

            if(i == 1){ subtext = "child information"; }
            else if(i+1 == count){subtext = "finalize account"; }
            else{ subtext =  $("#"+stepName+" .nickname").val() || "wellness content partner" }

            $(".osSaveButton #" + preStepName + "commands a").text("Next step: " +subtext);

            $("#" + stepName + "Prev").bind("click", function(e) {
                e.preventDefault();
                e.stopPropagation();
                $("#" + stepName).hide();
                $("#step" + (i - 1)).show();
            });
        }

        function createNextButton(i) {
            var stepName = "step" + i;
            $(".osSaveButton #" + stepName + "commands").append("<a href='#' id='" + stepName + "Next' class='next'>Next step: </a>");

            $("#" + stepName + "Next").bind("click", function(e) {
                e.stopPropagation();
                e.preventDefault();
                $('fieldset .formErrorText').remove();
                if( KIDSLINK.prototype.Validation(i, count) === false){
                    $('html, body').animate({
                        scrollTop: $('.formErrorText').offset().top-150
                    }, 1000)
                    return;
                }

                $("#" + stepName).hide();
                $("#step" + (i + 1)).show();
                $('body').animate( {scrollTop: 0}, 'fast' );
            });


        }
    }

    $.fn.kl_reGenerateMultiStep = function(options) {
        var element = this;
        var steps = $(element).find("fieldset");
        var count = steps.size();
        steps.each(function(i) {
             var $this= $(this);
            $('span[id^="step"]').remove();
            if ( $this.parent().is("div") ) {
                $this.unwrap();
            }
        });
        steps.show();
        $(element).kl_generateMultiStep();
        kl = new KIDSLINK();
        kl.generateKidsForm();
    }

    $.fn.kl_clickOnLastNext = function(options){
        var element = this;
        var steps = $(element).find("fieldset");
        var count = steps.size();
        var stepName = "step" + (count-2);
        $("#" + stepName + "Next").click();
    }
})(jQuery); 