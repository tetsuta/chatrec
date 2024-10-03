var Codex = function() {
    var on_run = false;
    var on_shift = false;
    var on_control = false;

    function main() {
	setupControlls();
    }

    function getRunResult(query){
        $.ajax({
            type: 'POST',
            url: new Config().getUrl() + '/',
            async: false,
            data: JSON.stringify({
                mode: "run",
		query: query
	    }),
        }).done(function(data) {
	    var new_content = $('#result').html() + data.message;
	    $('#result').html(new_content);
        });
    }

    function setupControlls() {
	$('#user_query').on('keydown', function(e) {
	    if (e.key == "Control") {
		on_control = true;
	    }

	    if (e.keyCode == 9) { // Tab
		this.setRangeText('\t', this.selectionStart, this.selectionEnd, 'end');
		return false;
	    }
	    if (e.key == "Enter") {
		if (on_control == true) {
		    call_process();
		}
	    }
	    console.log(e.key);
	    console.log(e.keyCode);
	});


	$('#user_query').on('keyup', function(e) {
	    if (e.key == "Control") {
		on_control = false;
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
	$('#run').removeClass("btn-primary");
	$('#run').addClass("btn-secondary");
	on_run = true;
	var query = $('#user_query').val();
	console.log(query);
	getRunResult(query);

	$('#run').removeClass("btn-secondary");
	$('#run').addClass("btn-primary");
	on_run = false;

	$('#user_query').val("");
    }

    return {
	main: main
    }
}();


$(function() {
    Codex.main();
});

$(window).on('load', function() {});


