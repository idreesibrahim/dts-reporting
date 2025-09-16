//= require jquery
//= require rails-ujs
//= require toastr
//= require jquery_nested_form
//= require_self

$('input[type=cancel]').on('click', function(){
	window.location.href= $(this).data('url');
});