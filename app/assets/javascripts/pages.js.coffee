# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(window).bind "load", ->
	

	bumpDown =->
		if $('.bump-down').length > 0
			if $( window ).width() > 600
				height = ($( window ).height())/4
			else
				height = 50
			
			$('.bump-down').css({"padding-top": height+"px"})

	bumpDown()

	$(window).resize ->
		bumpDown()