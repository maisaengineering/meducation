(function($) {
    $.fn.kl_generateMultiStep = function(options) {
        var element = this;
        var steps = $(element).find("fieldset");
        var count = steps.size();
        steps.each(function(i) {
            $(this).wrap("<div id='step" + i + "'></div>");
            $("#step"+i+" .bigNextButton ").prepend("<span id='step" + i + "commands'></span>");
            $("#step"+i+" .obPrevious").prepend("<span id='step" + i + "commands'></span>");

            $("#step"+i+" input[type='file']").fileValidator({
                onValidation: function(files){
                    if($("#step"+i+" input[type='file']").val()!=""){
                    $("#step"+i+" .obPhoto").parent().children('.errorFileField').remove() ;
                    }
                },
                onInvalid:    function(type, file){
                    $("#step"+i+" input[type='file']").val(null);
                    $("#step"+i+" .obPhoto").parent().append("<span class='errorFileField'>Warning : Invalid Image Format</span>");
                },
                type: 'image',
                maxSize: '20m'
            });

            if (i == 0) {createNextButton(i);}
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
            var preStepName = "step"+(i-1);
            var subtext ="" ;

            if(i == 1){ subtext = "child information"; }
            else if(i+1 == count){subtext = "finalize account"; }
            else{ subtext = ( $("#"+stepName+" .nickname").length > 0) ? $("#"+stepName+" .nickname").val()+" information"  :  "wellness content partner" }

            $("#" + preStepName+ " .bigNextButton").find('.bigNextButtonSubline').text(subtext );
            $(".obPrevious #" + stepName + "commands").append("<a href='#' id='" + stepName + "Prev' class='prev'>Previous step</a>");

            $("#" + stepName + "Prev").bind("click", function(e) {
                e.stopPropagation();
                $("#" + stepName).hide();
                $("#step" + (i - 1)).show();
            });
        }

        function createNextButton(i) {
            var stepName = "step" + i;
            $(".bigNextButton #" + stepName + "commands").append("<a href='#' id='" + stepName + "Next' class='next'>Next step</a>");

            $("#" + stepName + "Next").bind("click", function(e) {
                e.stopPropagation();
                e.preventDefault();
                $('fieldset .formErrorText').remove();
                if( KIDSLINK.prototype.Validation(i, count) === false){ return;}
                $("#" + stepName).hide();
                $("#step" + (i + 1)).show();
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