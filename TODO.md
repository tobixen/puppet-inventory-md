# TODO

## Module structure
* Consider refactoring to follow the install/config/service pattern used by many Puppet modules. Current structure (init.pp + instance.pp) is reasonable for module complexity, but could be split further if needed.

## Git synchronization (future enhancements)
* Configure optional remote for automatic pull/push synchronization between hosts
* API server integration:
  * Pull from remote before making changes
  * Commit and push immediately after changes to reduce conflict window
* Conflict resolution mechanism:
  * Per-host branches (e.g., `production-$HOSTNAME`)
  * Scripts for bidirectional merge between main and production branches (fast-forward only)
  * Flagging mechanism for conflicts that require manual resolution

## Completed
* ~~Git bare repo setup~~ - Implemented with `manage_git` parameter (default: true)
* ~~Post-receive hook for updating working directory~~ - Implemented
* ~~Git initialization in datadir~~ - Implemented
* ~~Optional external remote configuration~~ - Implemented via `git_remote` parameter
