Aspace Link-o-matic
============

Description
-----------

This is a plugin to help automate the insertion of links to digitized records into
Archives Space.  

It is based on the original Link-o-matic project ([GitHub repo](https://github.com/harvard-library/linkomatic).)

Code Repository
---------------

[GitHub repo](https://github.com/harvard-library/aspace-linkomatic).

Requirements
------------

* ACL to Olivia Servlet (https://wiki.harvard.edu/confluence/display/LibraryTechServices/SysDev+-+OLIVIA+DRS+Linking+Servlet)
* ArchivesSpace (compatible on v1.5.3)


Setup
-----

* Place the plugin in the archivesspace/plugins directory

* Edit config.rb to:
	* activate the `aspace-linkomatic` plugin
	For example, in config.rb:
	
	```
	## You may have other plugins
	AppConfig[:plugins] = ['local', 'aspace-linkomatic']
	```
	* set the database info: 
	```
	AppConfig[:db_url] = "jdbc:mysql://<server>/<dbname>?useUnicode=true&characterEncoding=UTF-8&user=<username>&password=<password>"
	```
    
    * set the NRS and OLIVIA urls:
    ```
    AppConfig[:nrs_url] = <NRS BASE URL>
    AppConfig[:olivia_url] = <OLIVIA BASE URL
    ```

* First time setup: run scripts/setup-database.sh to add the new enumeration to the ASpace table.
    
* To use LOM, users must have permission to:
	* create/update resources in this repository
	* create/update digital objects in this repository
	* initiate import jobs
	* cancel an import job

Known Issues
-------------

Aspace-linkomatic overrides ArchivesSpace's  frontend/app/views/shared/_tree.html.erb in order
to add a button to the resource tree in edit mode.  If another plugin attempts to override
this same file, it will only use the _tree.html.erb file for the last plugin added to the config.rb.


Issue Tracker
-------------

Any issues can be added to the [GitHub issue tracker](https://github.com/harvard-library/aspace-linkomatic/issues).



Contributors
------------
* [Valdeva "Dee Dee" Crema](https://github.com/ives1227)
* [Dave Mayo](https://github.com/pobocks) (Original Link-o-matic developer)

License
-------

Apache 2.0 - See the LICENSE file for details.

Copyright
---------

Copyright &copy; 2017 President and Fellows of Harvard College
