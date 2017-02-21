$(function () {
	
	var $owner_code_modal = null;
	$(document).bind("fetchdigitalshow.aspace", function(event) {
		$owner_code_modal = AS.openCustomModal("ownerCodeModal", "Enter Owner Code", AS.renderTemplate("owner_code_template"), 'small', {backdrop: 'static', keyboard: false});
		
		$('#fetchDigitalObjectsButton').removeClass('disabled');
		$('.btn-cancel').removeClass('disabled');
		$owner_code_modal.on('click', '#fetchDigitalObjectsButton', function (event) {
	    	event.preventDefault();
	    	event.stopImmediatePropagation();
	    	disableFetchButton();
	    	var resource_id = $("#archives_tree").data("root-id");
	    	$("#resource-id").val(resource_id);
	    	
	       $("#fetchProgress").show();
	       $owner_code_modal.on("hide.bs.modal", function (event){
				event.preventDefault();
		    	event.stopImmediatePropagation();
			});
	        
	    	$.ajax({
	            url: APP_PATH+"plugins/linkomatic/fetch_digital_objects",
	            type: "GET",
	            data: {resource_id: resource_id, other: $("#owner_code_text").val()},
	            dataType: "json",
	            success: function(data) {
	            	attachFetchClickHandler();
	            	var fetch_dialog_content = AS.renderTemplate("fetch_digital_objects_results_template", data);
	            	var $fetchmodal = AS.openCustomModal("fetchDigitalObjectsResultsModal", "Fetch Digital Objects Results", fetch_dialog_content, 'small', {backdrop: 'static', keyboard: false});
	            	$fetchmodal.on("hide.bs.modal", function (event){
	            		window.location.href = APP_PATH+"resources/"+resource_id;
	    				
	    			});
	            	$owner_code_modal.hide();
	            	$("#fetchProgress").hide();
	            },
	            error: function(xhr, status, err) {
	            	$owner_code_modal.hide();
	            }
	          });
	    	
	      });
		
		$owner_code_modal.on('click', '.btn-cancel', function (event) {
			//TODO: pass this to the controller to kill all the worker threads first and then redirect back to the resource
			
		});
		
	});
  
  
  
	$(document).bind("loadedrecordform.aspace", function(event, $container) {
		attachFetchClickHandler();
	});
	
	function attachFetchClickHandler() {
		if ($('.fetch-digital-objects')) {
			$('.fetch-digital-objects').removeClass('disabled');
			$('.fetch-digital-objects').click(function (event) {
				event.stopImmediatePropagation();
				$(document).triggerHandler("fetchdigitalshow.aspace", $(this));
			});
		}
	}
	
	function disableFetchButton() {
		$('.fetch-digital-objects').addClass('disabled');
		$('#fetchDigitalObjectsButton').addClass('disabled');
		$('.btn-cancel').addClass('disabled');
    }
	
	$(window).load(function(){
		var current_resource_id = $("#archives_tree").data("root-id");
		
		//If the resource is already looking for digital objects, disable the fetch button
		$.ajax({
			url: APP_PATH+"plugins/linkomatic/in_fetch_session",
	        type: "GET",
	        data: {resource_id: current_resource_id},
	        dataType: "json",
            success: function(data) {
            	if (data['response'] == true) {
            		disableFetchButton();
            	}

            }
		});
	});
	
	

	
});
