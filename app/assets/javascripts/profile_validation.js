function RegexEmail1(first_email)
  {       
    var emailStr = document.getElementById(first_email).value;  
    var emailRegexStr = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
    var isvalid = emailRegexStr.test(emailStr); 
    if(emailStr!="")
    {
      if (!isvalid)
      { 
        document.getElementById('parent_email_error').style.display = "none";
        document.getElementById('email1_format_error').style.display = "block";
        document.getElementById('first_email').className = "formInputError";            
        return false;
      }
       else
      {
        document.getElementById('email1_format_error').style.display = "none";
        document.getElementById('first_email').className = "standardForm";  
      }  
    }
  }
  
  function RegexEmail2(second_email)
  {   

    var emailStr = document.getElementById(second_email).value;  
    var emailRegexStr = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
    var isvalid = emailRegexStr.test(emailStr); 
    if(emailStr!="")
    {
      
      if (!isvalid)
      { 
        document.getElementById('email2_format_error').style.display = "block";
        document.getElementById('second_email').className = "formInputError";            
        return false;
      }
      else
      {
        document.getElementById('email2_format_error').style.display = "none";
        document.getElementById('second_email').className = "standardForm";  
      }
      var myVar2 = $("#start2").find('.myClass2').val();          

    }
  }

  function onlyNumbers(evt)
  {
    var e = event || evt; // for trans-browser compatibility
    var charCode = e.which || e.keyCode;

    if (charCode > 31 && (charCode < 47 || charCode > 57) )    
      return false;
    
    return true;
  }

    function change_format()
    {
        var str = document.getElementById('profile_univ__birthdate').value;
       if(str != "")
        {
            if(str.length==8)
            {
                var a = str.slice(0,2);
                var b = str.slice(2,4);
                var c = str.slice(4,8);
                var birthdate_format = a + "/" +b + "/" + c;
                document.getElementById('profile_univ__birthdate').value = birthdate_format;

            }

        }
    }

$(document).ready(function(){
    $('.parent_phone_number').blur(function() {
        var pattern = /\d{9,15}/;
       var space = (($(this).val()).replace(/\s+/g, ""));
        var current_phone = space.replace(/[^\w\s]/gi, '');
        if (pattern.test(current_phone)) {
            if(!isNaN(current_phone))
            {
            var a = current_phone.slice(0,3);
            var b = current_phone.slice(3,6);
            var c = current_phone.slice(6,$(this).val().length);
            phone_format = a + "-" + b + "-" + c;
            $(this).val(phone_format);
            }
        }


    });
});
