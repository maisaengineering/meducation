function goBack()
{
    $(".displayoption").css("display","none");
    $(".send_form").css("display","none");
}

function status(){
    $(".displayoption").css("display","block");
    // fetch all the selected child id's
    fetch_childids();
    var session= $('#session_data').val();
    var status= $('#enrollement_id').val();
    document.getElementById('prev_session').value = session;
    document.getElementById('prev_status').value = status;
}

function form(){
    $(".send_form").css("display","block");
    // fetch all the selected child id's
    fetch_childids();
    var session= $('#session_data').val();
    var status= $('#enrollement_id').val();
}

//common function to fetch all the child ids.
function fetch_childids(){
    // for remote call purpose, if needed
    var params = {
        season: $('#season_id').val().replace(' (current)',''),
        org_id: $('#org').val(),
        session: $('#session_data').val(),
        enrollement: $('#enrollement_id').val()
    };

    var children_ids = KLWindowObz.enrolleesByGlobalCheck(params);
    $('#kids_id').val(children_ids.join(','));
    $('#kids_selected').val(children_ids.join(','));
    $('#season').val($('#season_id').val().replace(' (current)',''));
}

$(document).ready(function(){

    // searching the kids when session alone changes
    $('#session_data').die().live('change', function() {
//        KLWindowObz.enrollees = [];
//        KLWindowObz.enrolleesGlobalCheck = false;
        var params = {"sort": $('#enrollees_sort').val() ,"direction": $('#enrollees_sort_direction').val()};
        searching_selected_data(params);
    });

    // searching kids when enrollement alone changes
    $('#enrollement_id').die().live('change', function() {
        $(".active").css("pointer-events","none");
//        KLWindowObz.enrollees = [];
//        KLWindowObz.enrolleesGlobalCheck = false;
        var params = {"sort": $('#enrollees_sort').val() ,"direction": $('#enrollees_sort_direction').val()};
        searching_selected_data(params);
    });

    // paginated results loader
    $('.enrollees_pagination a').die().live('click', function(e) {
        e.preventDefault();
        var params = {"sort": $('#enrollees_sort').val() ,"direction": $('#enrollees_sort_direction').val()};

        if(isNaN($(this).text())){
            var targetId, clazz = $(this).attr('class');
            if(clazz === 'next_page'){
                targetId = parseInt($(this).siblings('.current').text()) + 1;
            } else if(clazz === 'previous_page'){
                targetId = parseInt($(this).siblings('.current').text()) - 1;
            }
            params["page"] = targetId;
        }else{
            params["page"] = $(this).text();
        }

        searching_selected_data(params);
    });
    // paginated results loader
    $('.enrollees_order_by').die().live('click', function(e) {
        e.preventDefault();
        e.preventDefault();
        var params = {};
        params['sort'] = $(this).attr('data-sort')
        params['direction'] = $(this).attr('data-direction')
        searching_selected_data(params);
    });


    // common functionality for selecting kids
    function searching_selected_data(params) {
        $.ajax({
            url: "/organizations/selected_data",
            data: {
                season: $('#season_id').val().replace(' (current)',''),
                org_id: $('#org').val(),
                session: $('#session_data').val(),
                enrollement: $('#enrollement_id').val(),
                page: params ? params['page'] : 1,
                sort: params ? params['sort'] : null,
                direction: params ? params['direction'] : null
            },
            beforeSend: function () {
                $("#form_loading").show();
            },
            complete: function () {
                $('#form_loading').hide();
//                restoreEnrolleesSelection();

            },
            success: function (html) {
                // $('#form_loading').hide();
                $('#loading').empty();
                $('#loading').html(html);
            }
        });
    };

    function restoreEnrolleesSelection(){
        if(KLWindowObz.enrolleesGlobalCheck){
            $('#manageEnrolleesTable thead input:checkbox').prop('checked', true);
            $('#manageEnrolleesTable tbody input:checkbox').prop('checked', true);
        }else{
            $('#manageEnrolleesTable thead input:checkbox').prop('checked', false);
            $('#manageEnrolleesTable tbody input:checkbox').prop('checked', false);
//            KLWindowObz.enrollees = [];
            $('#manageEnrolleesTable tbody input:checkbox').each(function(){
                idx = -1;
                try{
                    idx = $.inArray($(this).attr('id'), KLWindowObz.enrollees);
                }catch(e){}
                $(this).prop('checked', idx > -1);
            });

        }
    };


    // when season changes changing the session drop down at change status
    $('#season_id').die().live('change', function() {
        $(".active").css("pointer-events","none");
        $.ajax({
            url: "/organizations/selected_session_for_status",
            data: { season: $('#season_id').val().replace(' (current)',''), org_id: $('#org').val()},
            cache: false,
            success: function(html){
                $('#session').empty();
                $('#session').append(html);
                $('#session #session_data_change').attr("id","session_data");
                $('#session_at_status').empty();
                $('#session_at_status').append(html);
                $('#session_data_change :selected').prop("selected", false);
                $('#session_data_change :selected').text('');
                $('#session_data_change :selected').val('');
                // on success loading kids data based on season,session and enrollment
                KLWindowObz.enrollees = [];
                KLWindowObz.enrolleesGlobalCheck = false;
                var params = {"page": 1,"sort": $('#enrollees_sort').val() ,"direction": $('#enrollees_sort_direction').val()};
                searching_selected_data(params);
            }
        })
    }).change();


    $("#universal").die().live('click', function(){
        if ($('#universal').attr('checked'))
        {
            $('.child_ckeck').attr('checked', true)
            var $parent_emails =  $.map($('input.child_ckeck[type="checkbox"]:checked'), function(n,i){ return $(n).attr('data-emails')});
            $parent_emails = $.unique($parent_emails .join().split(",")).join();
            $('#clipTarget').val($parent_emails);
            $(".active").css("pointer-events","auto");
        }
        else
        {
            $('#clipTarget').val("");
            $('.child_ckeck').attr('checked', false)
            $(".active").css("pointer-events","none");
        }
    });

    $(".child_ckeck").die().live('click', function(){

        if ($('input.child_ckeck[type="checkbox"]:checked').length>0)
        {
            var $parent_emails =  $.map($('input.child_ckeck[type="checkbox"]:checked'), function(n,i){ return $(n).attr('data-emails')});
            $parent_emails = $.unique($parent_emails .join().split(",")).join();
            $('#clipTarget').val($parent_emails);
            $(".active").css("pointer-events","auto");

        }
        else
        {   $('#clipTarget').val("");
            $(".active").css("pointer-events","none");
        }
    });


    $('#export_all_data').click(function (e) {
        e.preventDefault();

        // for remote call purpose, if needed
        var params = {
            season: $('#season_id').val().replace(' (current)',''),
            org_id: $('#org').val(),
            session: $('#session_data').val(),
            enrollement: $('#enrollement_id').val()
        };

        var children_ids = KLWindowObz.enrolleesByGlobalCheck(params);
        $.post("/organizations/export_csv_season", {profile_ids: children_ids.join(','), id: $('#org').val(), season_id: $('#season_id').val().replace(' (current)','')} );
    });

    $('#manageEnrolleesTable thead input:checkbox').die().live('click', function(e){
        var gCheckd = $(this).is(':checked');
        KLWindowObz.enrolleesGlobalCheck =  gCheckd;
        if(gCheckd === false){
            KLWindowObz.enrollees = [];
        }

//        $('#manageEnrolleesTable tbody input:checkbox').each(function(i, v){
//            var curId = $(this).attr('id');
//            var curIdx = KLWindowObz.enrollees.indexOf(curId);
//            if(gCheckd && curIdx < 0){
//                KLWindowObz.enrollees.push(curId);
//            }else if(curIdx > -1) {
//                KLWindowObz.enrollees.splice(curIdx, 1);
//            }
//        });
    });

    $('#manageEnrolleesTable tbody input:checkbox').die().live('click', function(e){
        var curId = $(this).attr('id');
        if(curId === undefined){
            return;
        }
        var curIdx = KLWindowObz.enrollees.indexOf(curId);
        if($(this).is(':checked') && curIdx < 0){
            KLWindowObz.enrollees.push(curId);
        }else if(curIdx > -1) {
            KLWindowObz.enrollees.splice(curIdx, 1);
        }
    });

   var client = new ZeroClipboard( $('#d_clip_button') );
    client.on( "aftercopy", function (event) {
        $('#d_clip_button').text("Copied!");
        $('#d_clip_button').attr('disabled','disabled');
    });

});

var KLWindowObz = {
    enrollees : [],
    enrolleesGlobalCheck : false,
    enrolleesByGlobalCheck  : function(params){
        var resp;
        try{
            if(KLWindowObz.enrolleesGlobalCheck){
                // get from remote
                req = $.ajax({
                    url: "/organizations/selected_data_kid_ids",
                    data: params,
                    cache: false,
                    async:   false
                });

                req.done(function(result){ resp = result;});
            }else{
                resp =   KLWindowObz.enrollees;
            }
        }catch(e){}

        return resp;
    }
};

contact_vi_mail = function(){
    var $parent_emails = $.unique($('#clipTarget').val().split(","))
    if($parent_emails.length>30){
        if (/MSIE (\d+\.\d+);/.test(navigator.userAgent))
        {
            $('#d_clip_button').css("display","none");
        }
        $('.modalBx').css("display","block");
    }else{
        window.location.href = "mailto:" + $parent_emails.join();
    }
}

model_box_close = function(){
    $('.modalBx').css("display","none")
}
