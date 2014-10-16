# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
	$(".more-or-less-stats a").click ->
		if $(".more-or-less-stats a").text() == "more stats"
			$(".more-stats").slideDown()
			$(".more-or-less-stats a").text("less stats")
		else if $(".more-or-less-stats a").text() == "less stats"
			$(".more-stats").slideUp()
			$(".more-or-less-stats a").text("more stats")
		