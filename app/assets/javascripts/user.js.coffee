# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).on 'ready page:load', ->
	$(".more-or-less-stats").click ->
		if $(".more-or-less-stats a").text("more stats")
			$(".more-stats").slideDown(400)
			$(".more-or-less-stats a").text("less stats")
		else
			$(".more-stats").slideUp(400)
			$(".more-or-less-stats a").text("more stats")
		