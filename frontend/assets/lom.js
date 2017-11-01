$(function () {
/* add the digital button via js like import-excel-spreadsheet */
    var fetchdobtnArr = {
	label: 'Fetch Digital Objects',
	cssClasses: 'btn-default fetch-digital-objects',
	onClick: function(event, btn, node, tree, toolbarRenderer) {
            get_owner_code();
	},
	isEnabled: function(node, tree, toolbarRenderer) {
            return true;
        },
        isVisible: function(node, tree, toolbarRenderer) {
            return !tree.large_tree.read_only;
        },
        onFormLoaded: function(btn, form, tree, toolbarRenderer) {
            $(btn).removeClass('disabled');
        },
        onToolbarRendered: function(btn, toolbarRenderer) {
            $(btn).addClass('disabled');
	},

    }
    /* add the button at the end, only at the resource level */
    var res = TreeToolbarConfiguration["resource"];
    TreeToolbarConfiguration["resource"] = [].concat(res).concat([fetchdobtnrr]);

    var get_owner_code = function (event) {
        event.stopImmediatePropagation();
        $(document).triggerHandler("fetchdigitalshow.aspace", $(this));
    }
	
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
		add_fetch_do_button();
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
