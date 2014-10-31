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
	
	$(".full-screen").click ->	
		$(".travel-map").css({'height' : '100%', 'position' : 'fixed', 'z-index' : '10001', 'top' : '0'})
		$("#map").css({'height' : '100%'})
		$(".unfull-screen").css({'display' : 'block'})
		$(".full-screen").hide()
	$(".unfull-screen a").click ->	
		$(".travel-map").css({'height' : '100%', 'position' : 'static'})
		$("#map").css({'height' : '400px'})
		$(".unfull-screen").css({'display' : 'none'})
		$(".full-screen").show()



	if $(".marquee").length > 0
		$(".marquee").marquee
			#speed in milliseconds of the marquee
			duration: 15000
	  
			#gap in pixels between the tickers
			gap: 50

			#time in milliseconds before the marquee will start animating
			delayBeforeStart: 0

			#'left' or 'right'
			direction: "left"

			#true or false - should the marquee be duplicated to show an effect of continues flow
			duplicated: true
		setTimeout (->
			check_reload()
		), 60000

	check_reload =->
		if $(".marquee").length > 0
			location.reload()


	$("a.instarange").fancybox()
		