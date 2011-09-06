function setup_tooltips() {
	var opacity_setting = 1;
	$('.tooltipped').tipsy({opacity:opacity_setting});
	$('.tooltipped-n').tipsy({opacity:opacity_setting,gravity:'s'});
	$('.tooltipped-w').tipsy({opacity:opacity_setting,gravity:'e'});
	$('.tooltipped-e').tipsy({opacity:opacity_setting,gravity:'w'});
}

function setup_tab_switching() {
	$('.tabs a').click(function() {
		var $tab = $(this);
		$tab.addClass('active').siblings().removeClass('active');
		var $content = $tab.parent().siblings('.' + $tab.attr('href'));
		$content.show().siblings('.tabcontent').hide();
		return false;
	});
}

function setup_placeholder_text() {
	$('input[placeholder],textarea[placeholder]').placeholder();
}

function tag_deletions() {
	$('.tag a.remove').click(function() {
		var $parent = $(this).parent();
		$parent.bind("ajax:success", function(event, data, status, xhr) {
			$parent.hide();
		});
	});
}

var prevent_closing_of_signup_modal = false;
function setup_signup_modal() {
	$('#join, a[href="#signup-modal"]').click(function() {
		var $modal = $('#join-login-modal');
		$modal.stop().fadeIn('fast');
		return false;
	});
	$('#join-login-modal .cover, #join-login-modal .close').click(function() {
		if (!prevent_closing_of_signup_modal) {
			$('#join-login-modal').stop().fadeOut('fast');
		}
	});
	$(document).keyup(function(e) {
	  if (e.keyCode == 27) { $('#join-login-modal').stop().fadeOut('fast'); } // escape
	});
}

function setup_rewarding() {
	$("a.reward:not(.disabled), a.rewarded:not(.disabled)").click(function() {
		var $reward_box = $('#reward-box');
		if ($reward_box.hasClass('open')) {
			$reward_box.removeClass('open').animate({top:'-422px'}, 500);
		} else {
			$reward_box.addClass('open').animate({top:'0'}, 500);
		}
		return false;
	});
	$('#reward-form').submit(function(event) {
		event.preventDefault(); 

		var $form = $(this);
		var amount = $form.find('#reward_amount').val();
		var comment = $form.find("#reward_comment").val();
		var story_id = $form.find("#reward_story_id").val();
		var impacted_by = $form.find("#reward_impacted_by").val();
		var url = $form.attr('action');

		$('#reward-box').addClass('loading');
		$.post(url,
			{
				"reward[amount]":amount,
				"reward[comment]":comment,
				"reward[story_id]":story_id,
				"reward[impacted_by]":impacted_by
			},
			function(data) {
				$("#reward-box .inner").html(data);
				$('#reward-box').removeClass('loading').addClass('thanks');
			}
		);
	});
}

function handle_signup_login_form_validation() {
	// we have to remove the extra checkbox Rails inserts for the 0 value
	$('#join-form input[name="user[tos_accepted]"][value="0"]').remove();
	var $beta_join_button = $('#beta-join-form input[type="submit"]');
	$('#join-form').validate({
		rules: {
			'user[first_name]': 'required',
			'user[last_name]': 'required',
			'user[email]': {required:true,email:true},
			'user[password]': {required:true,minlength:6},
			'user[tos_accepted]': {required:true}
		},
		messages: {
			'user[first_name]':'Required',
			'user[last_name]':'Required',
			'user[email]':{required:'Required'},
			'user[tos_accepted]': {required:'Must be accepted'}
		}
	});
	$('#login-form').validate({
		rules: {
			'user[email]': {required:true,email:true},
			'user[password]': 'required'
		},
		messages: {
			'user[email]':{required:'Required'},
			'user[password]':'Required'
		}
	});
}

function setup_modal_presenter_links(selector, autoTrigger) {
	var fancybox = $(selector).fancybox({
		width: '98%',
		height: '98%',
		padding: 0,
		autoScale: false,
		autoDimensions: false,
		overlayColor: '#000',
		overlayOpacity: 0.7,
		scrolling: 'no',
		ajax: {
			data: 'modal=1'
		},
		onComplete: function() {
			viewer.initialize();
			viewer.goto_page(1);
			setup_rewarding();
		}
	});
	if (autoTrigger) {
		fancybox.trigger('click');
	}
}

var infinite_loading = false;
var infinite_page = 2;
var infinite_done = false;
function setup_following_stream_infinite_scroll() {
	var $container = $('#right-sidebar');
	var $stream = $('#right-sidebar ul.rewards');
	var $spinner = $('#right-sidebar .spinner');
	var user_id = $('#right-sidebar #user_id').text();
	$container.scroll(function() {
		var heightOfStream = $stream.height();
		var pixelsScrolled = $container.scrollTop() + $container.height();
		if (pixelsScrolled > heightOfStream && !infinite_loading && !infinite_done) {
			$spinner.show();
			infinite_loading = true;
			$.get('/users/' + user_id + '/stream?page=' + infinite_page, function(data) {
				$stream.append(data);
				infinite_loading = false;
				infinite_page += 1;
				if (data.trim() == "") {
					$('#right-sidebar .spinner').addClass('done').text('No more rewards.');
					infinite_done = true;
				}
			});
		}
	});
}

$(document).ready(function() {
	setup_tooltips();
	setup_tab_switching();
	setup_placeholder_text();
	tag_deletions();
	setup_signup_modal();
	setup_rewarding();
	handle_signup_login_form_validation();	
	setup_modal_presenter_links('a.modal');
	setup_following_stream_infinite_scroll();
	
	$("a.disabled").click(function() {return false;})
	
	$.fn.colorPicker.defaultColors = ['000', '666', '999', 'ccc', 'fff', 'f42652', 'f7d3db', 'ffa801', 'ffebc5', 'fff10f', 'fffcd2', '1ea337', 'c8f2d0', '00aeef', 'c0eeff', '985faf', 'f5deff', '7a5116', 'e1d5c3'];
});

function log(message) {
	if (console && console.log) {
		console.log(message);
	}
}