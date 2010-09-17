// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function update_error_flash(errors) {
	if (errors.join) {
		errors = errors.join("<br/>");
	}
	jQuery('#flash_error').html(errors);
	if (errors == "") {
		jQuery("#flash_error").hide();
	} else {
		jQuery("#flash_error").show();
	}
}

function update_notice_flash(message) {
	jQuery('#flash_notice').html(message);
	if (message == "") {
		jQuery('#flash_notice').hide();
	} else {
		jQuery('#flash_notice').show();
	}
}

