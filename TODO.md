* Quite many puppet modules comes with classes like install, config, params, etc - I suppose there is some "best current practice" pattern here, perhaps it should be followed also by this class?
* The bare git inventory repo seems not to be configured through the module.
  * It should be set up by vcsrepo, if possible
  * It may optionally be configured with a remote, and pull frequently from the remote
  * It should be configured so that after every push (or pull) a git hook is run, which will automatically update the datadir with the latest version.
  * If the API server isn't configured for it yet, it should be configured to always commit and push after every change it does
  * Conflicts needs to be flagged somehow, and there must be some way for the developer to fetch all branches and compare them locally.  (probably we should have a separate branch like "production-$HOSTNAME" and scripts that merges any changes bidrectionally between main and production-$HOSTNAME as long as it's possible to do it through fast-forward)
  
