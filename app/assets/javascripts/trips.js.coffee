# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$ ->
	$(".date_picker").datepicker()
	
$(document).on "nested:fieldAdded", (event) ->
	# this field was just inserted into your form
	field = event.field
  
	# it's a jQuery object already! Now you can find date input
	dateField = field.find(".date_picker")
  
	# and activate datepicker on it
	dateField.datepicker()