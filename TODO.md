# TODO

## Set up a public demo site on srv1
* Deploy a publicly accessible instance with fake/example content
* Useful for showcasing the module and inventory-md project

## Module structure
* Consider refactoring to follow the install/config/service pattern used by many Puppet modules. Current structure (init.pp + instance.pp) is reasonable for module complexity, but could be split further if needed.

## Git synchronization (future enhancements)
* Conflict resolution mechanism:
  * Per-host branches (e.g., `production-$HOSTNAME`)
  * Scripts for bidirectional merge between main and production branches (fast-forward only)
  * Flagging mechanism for conflicts that require manual resolution

## Completed
* ~~Release to forge.puppetlabs.com~~ - Published as v0.2.1
* ~~Git bare repo setup~~ - Implemented with `manage_git` parameter (default: true)
* ~~Post-receive hook for updating working directory~~ - Implemented
* ~~Git initialization in datadir~~ - Implemented
* ~~Optional external remote configuration~~ - Implemented via `git_remote` parameter
* ~~API server git integration~~ - Pull before changes, commit and push after (in inventory-system repo)
