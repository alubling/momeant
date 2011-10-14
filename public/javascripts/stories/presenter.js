$(function() {
	
	window.Page = Backbone.Model.extend({
		visible: false,
		
		initialize: function() {
			this.id = '#page_' + this.get('number');
		}
	});
	
	window.PageView = Backbone.View.extend({
		
		initialize: function() {
			this.el = $(this.model.id);
			this.listing = $('#metadata .pages a[page="' + this.model.get('number') + '"]');
			
			_.bindAll(this, 'update_visibility');
			this.model.bind('change:visible', this.update_visibility);
		},
		
		update_visibility: function() {
			if (this.model.get('visible')) {
				$(this.el).fadeIn('fast');
				this.listing.addClass('selected');
			} else {
				$(this.el).fadeOut('fast');
				this.listing.removeClass('selected');
			}
		}
	});
	
	window.PageList = Backbone.Collection.extend({
		model: Page,
		
		turn_on_page: function(number) {
			_(this.models).each(function(page) {
				if (page.get('number') == number) {
					page.set({visible: true});
				} else {
					page.set({visible: false});
				}
			});
		}
	});
	
	window.Pages = new PageList;
	
	window.PresenterView = Backbone.View.extend({
		
		el: $('#presenter'),
		
		events: {
			'click #previous-page': 'goto_previous_page',
			'click #next-page':     'goto_next_page',
			'click .pages a':       'jump_to_page',
			'click #content-cover': 'close_reward_modal'
		},
		
		initialize: function() {
			var page_number = 1;
			$('#pages').children().each(function(page) {
				var $page_li = $(this);
				var page = new Page({number: page_number, visible: (page_number == 1)});
				var page_view = new PageView({model: page});
				Pages.add(page);
				page_number += 1;
			});
			
			this.current_page = 1;
			this.previous_button = this.$('#previous-page');
			this.next_button = this.$('#next-page');
			this.$('ul#pages li').swipe({swipe:this.swipe,threshold:0});
			this.goto_page_in_url_or_default();
			this.setup_key_bindings();
		},
		
		goto_previous_page: function() {
			this.goto_page(this.current_page - 1);
		},
		
		goto_next_page: function() {
			this.goto_page(this.current_page + 1);
		},
		
		goto_page: function(number) {
			if (number >= 1 && number <= Pages.length && number != this.current_page) {
				this.current_page = number;
				Pages.turn_on_page(this.current_page);
			}
			
			if (this.current_page == 1) {
				this.previous_button.fadeOut('fast');
			} else {
				this.previous_button.fadeIn('fast');
			}
			log('current page: ' + this.current_page);
			log('total pages: ' + Pages.length);
			if (this.current_page == Pages.length) {
				this.next_button.fadeOut('fast');
			} else {
				this.next_button.fadeIn('fast');
			}
		},
		
		swipe: function(event, direction) {
			if (direction == "left") {
				this.goto_next_page();
			} else if (direction == "right") {
				this.goto_prev_page();
			}
		},
		
		jump_to_page: function(e) {
			var $link = $(e.currentTarget);
			var number = parseInt($link.attr('page'));
			this.goto_page(number);
			return false;
		},
		
		close_reward_modal: function() {
			RewardModal.hide_modal();
		},
		
		goto_page_in_url_or_default: function() {
			var url = window.location.href;
			if (url.indexOf('#page') != -1) {
				var number = parseInt(url.substring(url.indexOf('#page') + 5));
				this.goto_page(number);
			} else {
				this.goto_page(1);
			}
		},
		
		setup_key_bindings: function() {
			var presenter = this;
			$(document).keyup(function(e) {
				if (!RewardModal.modal_open) {
				  if (e.keyCode == 39) { presenter.goto_next_page(); } 					// right arrow
					if (e.keyCode == 37) { presenter.goto_previous_page(); }			// left arrow
				}
			});
		}
	});
	
	window.RewardModalView = Backbone.View.extend({
		el: $('#reward-modal'),
		
		events: {
			'click #reward-modal-tab':        'toggle_modal',
			'click #share input':           	'toggle_sharing',
			'click #toggle-reward-stream':    'toggle_reward_list',
			'submit #reward-form':            'submit_reward',
			'keyup #reward_amount':           'reward_amount_keypress',
			'click #how-much #ticker .up':    'increment_reward_amount',
			'click #how-much #ticker .down':  'decrement_reward_amount'
		},
		
		initialize: function() {
			this.modal_open = false;
			this.setup_key_bindings();
		},
		
		show_modal: function() {
			$(this.el).animate({top: 0}, 300);
			$('#content-cover').show();
			this.modal_open = true;
			mpq.track('Opened Reward Modal', {anonymous_id: '#{session[:analytics_anonymous_id]}'});
		},
		
		hide_modal: function() {
			$(this.el).animate({top: '-500px'}, 300);
			$('#content-cover').hide();
			this.modal_open = false;
			$('#its-you-arrow').hide();
		},
		
		toggle_modal: function() {
			if (this.modal_open) {
				this.hide_modal();
			} else {
				this.show_modal();
			}
			return false;
		},
		
		toggle_sharing: function(e) {
			var $checkbox = $(e.currentTarget);
			var $hidden_field = $('#share_' + $checkbox.attr('id'));

			if ($checkbox.is(':checked')) {
				$hidden_field.val('yes')
			} else {
				$hidden_field.val('')
			}
		},
		
		toggle_reward_list: function() {
			$('#reward-list, #your-reward').toggleClass('closed');
		},
		
		submit_reward: function(e) {
			var $form = $(e.currentTarget);
			e.preventDefault(); 

			var amount = $form.find('#reward_amount').val();
			var comment = $form.find("#reward_comment").val();
			var story_id = $form.find("#reward_story_id").val();
			var impacted_by = $form.find("#reward_impacted_by").val();
			var share_with_twitter = $form.find("#share_twitter").val();
			var share_with_facebook = $form.find("#share_facebook").val();
			var url = $form.attr('action');

			$('#reward-box-outer').addClass('loading');
			$.post(url,
				{
					"reward[amount]":amount,
					"reward[comment]":comment,
					"reward[story_id]":story_id,
					"reward[impacted_by]":impacted_by,
					"share[twitter]":share_with_twitter,
					"share[facebook]":share_with_facebook
				},
				function(data) {
					$("#your-reward .inner").html(data);
					var $new_reward = $('#new-reward');
					$new_reward.find('.amount').text(amount);
					$new_reward.find('.comment .text').text(comment);
					$new_reward.slideDown();
					$('#its-you-arrow').show();
				}
			);
		},
		
		reward_amount_keypress: function(e) {
			if (e.keyCode == 38) { // up arrow
				this.increment_reward_amount();
			}
			else if (e.keyCode == 40) { // down arrow
				this.decrement_reward_amount();
			}
		},
		
		increment_reward_amount: function() {
			var $amount = $('#reward_amount');
			var value = parseInt($amount.val());
			if (isNaN(value)) {
				$amount.val('1');
			} else {
				$amount.val(value + 1);
			}
		},

		decrement_reward_amount: function() {
			var $amount = $('#reward_amount');
			var value = parseInt($amount.val());
			if (isNaN(value)) {
				$amount.val('1');
			}	else if (value == 1) {
				// do nothing
			} else {
				$amount.val(value - 1);
			}
		},

		setup_key_bindings: function() {
			var modal = this;
			$(document).keyup(function(e) {
			  if (e.keyCode == 27) { modal.toggle_modal(); } 			// escape
			});
		}
	});
	
	window.Presenter = new PresenterView;
	window.RewardModal = new RewardModalView;
	
	// TODO: move reward JS into the modal object here
	
});