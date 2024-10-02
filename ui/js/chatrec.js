var Codex = function() {
    var on_run = false;
    var on_shift = false;
    var on_control = false;

    function main() {

	setupControlls();

    }

    function getRunResult(code){
        $.ajax({
            type: 'POST',
            url: new Config().getUrl() + '/',
            async: false,
            data: JSON.stringify({
                mode: "run",
		code: code
	    }),
        }).done(function(data) {
	    $('#result').html(data.message);
        });
    }

    function setupControlls() {
	$('#codetext').on('keydown', function(e) {
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


	$('#codetext').on('keyup', function(e) {
	    if (e.key == "Control") {
		on_control = false;
		// console.log("shift off");
	    }

	    setLineNumber();
	});

	$('#clear').on('click', function() {
	    $('#codetext').val("");
	    setLineNumber();
	});

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
	var code = $('#codetext').val();
	// console.log(code);
	getRunResult(code);

	$('#run').removeClass("btn-secondary");
	$('#run').addClass("btn-primary");
	on_run = false;
    }

    function setLineNumber() {
        const num = $('#codetext').val().split("\n").length;
        $('#numberRow').html(Array(num).fill("<span></span>").join(""));
    }

    return {
	main: main
    }
}();


$(function() {
    Codex.main();
});

$(window).on('load', function() {});


