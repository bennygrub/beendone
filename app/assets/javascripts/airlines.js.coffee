# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
		
	custom_marker =->
		if $(".custom_marker_content").length < 1
			setTimeout (->
				custom_marker()
			), 10
		else
			$(".custom_marker_content").each (index) ->
				$(".custom_marker_content").eq(index).parent().parent().css({'box-shadow' : 'none','-moz-box-shadow' : 'none', '-webkit-box-shadow' : 'none'});
			

	custom_marker()


