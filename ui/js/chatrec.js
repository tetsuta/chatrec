var Codex = function() {
    var on_run = false;
    var on_shift = false;
    var on_control = false;
    var key_down_code = null;

    function main() {
	setupControlls();
    }

    function getRunResult(query, user_id){
        $.ajax({
            type: 'POST',
            url: new Config().getUrl() + '/',
            data: JSON.stringify({
                mode: "run",
		user_id: user_id,
		query: query
	    }),
        }).done(function(data) {
	    var new_content = $('#result').html() + data.message;
	    $('#result').html(new_content);
	    $("html,body").animate({scrollTop:$('#user_query').offset().top});
	    
	    $('#run').removeClass("btn-secondary");
	    $('#run').addClass("btn-primary");
	    $('#user_query').attr("disabled", false);
	    $('#status').html("<br><br>");
	    on_run = false;
	    $('#user_query').val("");
        });
    }

    function setupControlls() {
	$('#user_id').on('focusin', function() {
	    $('#warning').html("");
	});

	$('#user_query').on('keydown', function(e) {
	    if (e.key == "Control") {
		on_control = true;
	    }

	    if (e.key == 'a') {
		console.log("a");
	    }

	    if (e.key == 'b') {
		console.log("b");
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

	// $('#clear').on('click', function() {
	// });

	$('#run').on('click', function() {
	    if (on_run == false) {
		call_process();
	    }
	});
    }


    function call_process() {
	var user_id = $('#user_id').val();

	if (user_id == "") {
	    console.log("empty ID!")
	    $('#warning').html("ページの先頭にある User Infoにニックネームを入力してください");
	    return;
	} else {
	    console.log(user_id)
	}

	var query = $('#user_query').val();
	if (query == "") {
	    console.log("empty");
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


