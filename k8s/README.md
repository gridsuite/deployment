# Deployment Structure
The deployment is structured with the following folders

* resources/ : folders creating disjoint bare resources sets
* bases/ : folders combining bare resource sets into standalone bare resources sets
* overlays/ : folders tweaking final bare resource sets
* components/ : folders to define common settings to be optionally applied downstream
* live/ : one to one mapping to deployments, with all downstream settings from components applied

This design is to allow:
- downstream choice of resources to deploy (e.g. full gridsuite or just gridstudy)
- common configuration to be applied also to downstream resources (commonLabel, or runAsNoRoot)

limitations:
- the gridsuite component should be applied last so that settings are applied on last resources, so it can
overwrite things configured by downstream. A workaround is to configure the things that would be overriden
in a patch, which is a little more verbose
