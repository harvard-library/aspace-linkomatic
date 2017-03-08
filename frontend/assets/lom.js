$(function () {
	
	var $owner_code_modal = null;
	$(document).bind("fetchdigitalshow.aspace", function(event) {
		$owner_code_modal = AS.openCustomModal("ownerCodeModal", "Enter Owner Code", AS.renderTemplate("owner_code_template"), 'small', {backdrop: 'static', keyboard: false});
		$("#fetchProgress").hide();
		$owner_code_modal.on('click', '#fetchDigitalObjectsButton', function (event) {
	    	event.preventDefault();
	    	event.stopImmediatePropagation();
	    	var resource_id = $("#archives_tree").data("root-id");
	    	$("#resource-id").val(resource_id);

	        
	    	$.ajax({
	            url: APP_PATH+"plugins/linkomatic/fetch_digital_objects",
	            type: "GET",
	            data: {resource_id: resource_id, other: $("#owner_code_text").val()},
	            dataType: "json",
	            error: function(xhr, status, err) {
	            	$("#fetchProgress").html(xhr.responseText);
	            	$("#fetchProgress").show();
	            },
	            complete: function(xhr, status) {
	            	var response = JSON.parse(xhr.responseText);
	            	if (response.success) {
	            		attachFetchClickHandler();
	            		var fetch_dialog_content = AS.renderTemplate("fetch_digital_objects_results_template", response.success);
	            	 	var $fetchmodal = AS.openCustomModal("fetchDigitalObjectsResultsModal", "Fetch Digital Objects Results", fetch_dialog_content, 'small', {backdrop: 'static', keyboard: false});
	            	  	$owner_code_modal.hide();
	            	}
	            	else if (response.error){
	            		$("#fetchProgress").html(response.error);
	            		$("#fetchProgress").show();
	            	}
	            }
	          });
	    	
	      });
		
		$owner_code_modal.on('click', '.btn-cancel', function (event) {
			$owner_code_modal.hide();
		});
		
	});
  
  
  
	$(document).bind("loadedrecordform.aspace", function(event, $container) {
		attachFetchClickHandler();
	});
	
	function attachFetchClickHandler() {
		if ($('.fetch-digital-objects')) {
			$('.fetch-digital-objects').click(function (event) {
				event.stopImmediatePropagation();
				$(document).triggerHandler("fetchdigitalshow.aspace", $(this));
			});
		}
	}

});
