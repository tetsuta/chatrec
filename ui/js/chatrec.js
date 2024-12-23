var Codex = function() {
    var on_run = false;
    var on_shift = false;
    var on_control = false;
    var key_down_code = null;
    var session_id = null;
    var org = null;

    function main() {
	setupControlls();
    }

    function call_clear(){
	var user_id = $('#user_id').val();
	if (user_id == "") {
	    $('#result').html("");
	    $("html,body").animate({scrollTop:$('#user_query').offset().top});
	    $('#user_query').focus();
	    return;
	    // user_idが指定されていなかったら、resultを消すだけでサーバは呼ばない
	}

	org = $('#user_query').data('org');
	if (org == null) {
	    org = "";
	}

        $.ajax({
            type: 'POST',
            url: new Config().getUrl() + '/',
            data: JSON.stringify({
                mode: "clear",
		session_id: session_id,
		user_id: org + "_" + user_id
	    }),
        }).done(function(data) {
	    session_id = data.session_id;
	    $('#result').html("");
	    $("html,body").animate({scrollTop:$('#user_query').offset().top});
	    $('#user_query').focus();
        });
    }

    function call_history(){
	var user_id = $('#user_id').val();
	if (user_id == "") {
	    $('#warning1').html("ページの先頭にある User Infoに入力してください");
	    return;
	}

	org = $('#user_query').data('org');
	if (org == null) {
	    org = "";
	}

        $.ajax({
            type: 'POST',
            url: new Config().getUrl() + '/',
            data: JSON.stringify({
                mode: "history",
		session_id: session_id,
		user_id: org + "_" + user_id
	    }),
        }).done(function(data) {
	    session_id = data.session_id;
	    $('#result').html(data.message);
	    $("html,body").animate({scrollTop:$('#user_query').offset().top});
	    $('#status').html("<br><br>");
	    $('#user_query').focus();
        });
    }


    function getRunResult(query, user_id){
	org = $('#user_query').data('org');
	if (org == null) {
	    org = "";
	}

        $.ajax({
            type: 'POST',
            url: new Config().getUrl() + '/',
            data: JSON.stringify({
                mode: "run",
		session_id: session_id,
		user_id: org + "_" + user_id,
		query: query
	    }),
        }).done(function(data) {
	    session_id = data.session_id;
	    var new_content = $('#result').html() + data.message;
	    $('#result').html(new_content);
	    $("html,body").animate({scrollTop:$('#user_query').offset().top});
	    
	    $('#run').removeClass("btn-secondary");
	    $('#run').addClass("btn-primary");
	    $('#user_query').attr("disabled", false);
	    $('#status').html("<br><br>");
	    on_run = false;
	    $('#user_query').val("");
	    $('#user_query').focus();
        });
    }

    function setupControlls() {
	$('#user_id').on('focusin', function() {
	    $('#warning1').html("");
	});

	$('#user_query').on('focusin', function() {
	    $('#warning2').html("");
	});

	$('#user_query').on('keydown', function(e) {
	    if (e.key == "Control") {
		on_control = true;
	    }

	    key_down_code = e.keyCode;
	    // console.log(e.key);
	    // console.log(e.keyCode);
	});


	$('#user_query').on('keyup', function(e) {
	    if (e.key == "Control") {
		on_control = false;
	    }
	    
	    // かな漢字変換中の Enterではなく、漢字が確定後の Enterのみを通す
	    if ((e.key == "Enter") && (e.keyCode == key_down_code)) {
		// if (on_control == true) {
		call_process();
		// }
	    }
	});

	$('#clear').on('click', function() {
	    call_clear()
	});

	$('#history').on('click', function() {
	    call_history()
	});

	$('#run').on('click', function() {
	    if (on_run == false) {
		call_process();
	    }
	});
    }


    function call_process() {
	var user_id = $('#user_id').val();

	if (user_id == "") {
	    $('#warning1').html("ページの先頭にある User Infoに入力してください");
	    return;
	}

	var query = $('#user_query').val();
	if (query == "") {
	    console.log("empty");
	    $('#warning2').html("左側に何か入力した後にこのボタンを押してください");
	} else {	
	    $('#run').removeClass("btn-primary");
	    $('#run').addClass("btn-secondary");
	    $('#status').html("考え中...");
	    $('#user_query').attr("disabled", true);
	    on_run = true;

	    getRunResult(query, user_id);
	}
    }

    return {
	main: main
    }
}();


$(function() {
    Codex.main();
});

$(window).on('load', function() {});


