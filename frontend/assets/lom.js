$(function () {
	var aspace_version = (typeof(TreeToolbarConfiguration) === 'undefined')? 1 : 2;
	var $owner_code_modal = null;

        /* define the button that goes on the Resource's tree button line, if v2 */
	var linkomaticArr = {
            label: 'Fetch Digital Objects',
            cssClasses: 'btn-default',
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
	};

    	/* insert the button into the tree buttons configuration (AS V2) */
	if (aspace_version !== 1) {
	    var res = TreeToolbarConfiguration["resource"];
	    TreeToolbarConfiguration["resource"] = [].concat(res).concat([linkomaticArr]);
	}

	/* contains the html for V2 */
	var owner_code_modal_html;

	var get_owner_code = function() {
	    $.ajax({
		    url: APP_PATH + "plugins/linkomatic/ownercode",
			type: "POST",
		    /*			data: {resource_id: resource_id}, */
			dataType: "html",
			success: function(data) {
			owner_code_modal_html = data;
			openOwnerCodeModal();
		    },
			error: function(xhr,status,err) {
			alert("ERROR: " + status + " " + err);
		    }
		});
	};
	var openOwnerCodeModal = function () {
	    var $resource_form = $("#resource_form");
	    var resource_id = $resource_form.find("#id").val();
	    $owner_code_modal = AS.openCustomModal("ownerCodeModal", "Enter Owner Code",
						   (aspace_version == 1 ?  AS.renderTemplate("owner_code_template") : owner_code_modal_html),
						   'small', {backdrop: 'static', keyboard: false});
	    $("#fetchProgress").hide(); 
	    $owner_code_modal.on('click', '#fetchDigitalObjectsButton', function (event) {
		    event.preventDefault();
		    event.stopImmediatePropagation();
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
	};
	$(document).bind("fetchdigitalshow.aspace", function(event) {
		openOwnerCodeModal(resource_id); 
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
	    };
	}
    });
