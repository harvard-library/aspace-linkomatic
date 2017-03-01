{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 2,
    "type" => "object",

    "properties" => {
      "owner_code" => {
        "type" => "string",
        "ifmissing" => "error"
      },
      "resource_id" => {
        "type" => "string",
        "ifmissing" => "error"
      },
      "source" => {
        "type" => "string",
        "ifmissing" => "error"
      }
    }
  }
}