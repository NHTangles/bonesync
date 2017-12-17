This script is designed to support the multi-server hardfought.org network
by syncing bones files between servers.  The general idea is that as bones
are created and consumed on each server, these changes are replicated to
other servers.
Logic breakdown:
for each remote:
    fetch current bones list.
    compare to previous list collected from that remote.
    for each deleted (consumed) bones file, delete locally (if md5sum matches)
    for each new bones file, copy it locally if it doesn't already exist
       (note that a different bones may have been created locally for same level - this should take precedence)
when that's done, use find/xargs/md5sum to make/publish a list of current bones files.

