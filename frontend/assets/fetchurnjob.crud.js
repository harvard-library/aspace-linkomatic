$(function() {

  var initFetchUrnJobForm = function() {
    var $form = $('#jobfileupload');
    var jobType;
    
    /*$form.submit(function(event) {
    	event.preventDefault();
    	alert( "Handler for .submit() called." );
    	if (jobType == "fetch_urn_job")
        {
        	$form.attr("action", "/plugins/fetch_urns/create");
        }
	});*/
   /* $(".btn:submit", $form).on("click", function(event) {
        event.stopPropagation();
        event.preventDefault();
        if (jobType == "fetch_urn_job")
        {
        	$form.attr("action", "/plugins/fetch_urns/create");
        }
        $form.submit();
	})*/

    $("#job_job_type_", $form).change(function() {
      $("#job_form_messages", $form).empty()

      if ($(this).val() === "fetch_urn_job") {
    	  $form.attr("action", "/plugins/fetch_urns/create");
    	  jobType = "fetch_urn_job";
          $("#noImportTypeSelected", $form).hide();
          $("#job_type_fields", $form)
            .empty()
            .html(AS.renderTemplate("template_fetch_urn_job", {id_path: "fetch_urn_job", path: "fetch_urn_job"}));

          // init findAndReplaceForm
          var $selectRecordType = $("#fetch_urn_job_record_type_");
          var $selectProperty = $("#fetch_urn_job_property_");

          $(".linker:not(.initialised)").linker();
          $selectRecordType.attr('disabled', 'disabled');
          $selectProperty.attr('disabled', 'disabled');

          $("#fetch_urn_job_ref_").change(function() {
            var resourceUri = $(this).val();
            if (resourceUri.length) {
              var id = /\d+$/.exec(resourceUri)[0]
              $.ajax({
                url: "/resources/" + id + "/models_in_graph",
                success: function(typeList) {
                  var oldVal = $selectRecordType.val();
                  $selectRecordType.empty();
                  $selectRecordType.append($('<option>', {selected: true, disabled: true})
                    .text(" -- select a record type --"));
                  $.each(typeList, function(index, valAndText) {
                    var opts = { value: valAndText[0]};
                    if (oldVal === valAndText[0])
                      opts.selected = true;

                    $selectRecordType.append($('<option>', opts)
                                             .text(valAndText[1]));
                  });
                  $selectRecordType.removeAttr('disabled');
                  if (oldVal != $selectRecordType.val())
                    $selectRecordType.triggerHandler('change');
                }
              });

            }
          });

          $selectRecordType.change(function() {
            var recordType = $(this).val();
            $.ajax({
              url: "/schema/" + recordType + "/properties?type=string&editable=true",
              success : function(propertyList) {
                $selectProperty.empty();

                $.each(propertyList, function(index, valAndText) {
                  $selectProperty
                    .append($('<option>', { value: valAndText[0] })
                            .text(valAndText[1]));
                });

                $selectProperty.removeAttr('disabled');
              }
            });
          });

        } else {
        	$form.attr("action", "/jobs");
        	jobType = null;
        } 
    });

    $("#job_job_type_", $form).trigger("change");
  };
	initFetchUrnJobForm();
});
