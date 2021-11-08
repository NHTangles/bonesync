This script is designed to support the multi-server hardfought.org network
by syncing bones files between servers.  The general idea is that as bones
are created and consumed on each server, these changes are replicated to
other servers.
## Logic breakdown:
* for each remote:
    * fetch current bones list.
    * compare to previous list collected from that remote.
    * for each deleted (consumed) bones file, delete locally (if md5sum matches)
    * for each new bones file, copy it locally if it doesn't already exist
       * (note that a different bones may have been created locally for same level - this should take precedence)
* when that's done, use find/xargs/md5sum to make/publish a list of current bones files.

## General instructions:
* Install the script to a directory on each server (eg: `/opt/bonesync`)
* Make a `bonesync.conf` file (using the template) in the same directory. Config in here will be specific to each server.
* Edit `remotes.txt` with the complete list of servers you want to replicate between, and save this wherever `REMOTES` points to
in the config.
* Generate an ssh key pair without a passphrase for the root user on each system.
* Create a restricted user on each server, like this:
`nhsync:x:1003:1004:Nethack DB Sync,,,:/home/nhsync:/bin/rbash`
(`/bin/rbash` is restricted shell - we need a limited shell to make scp work)

* In the user's `authorized_keys` file, (in `/home/nhsync/.ssh` using the example above) add all of the public keys for the root users of the other servers, preceded with the 'restrict' keyword. This restricts various ssh features such as port-forwarding and allocating a pty.  It does not quite restrict us to only downloading via scp, but it's better than nothing. 
eg: `restrict ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC[...] root@eu-hdf`

* IMPORTANT: Run the script once on each host, and accept the ssh connections so they are added to `known_hosts`.

* Add the script to cron on each server.  Every 15 minutes is probably sufficient.  For best results, run all instances at the same interval, but offset. eg:

  * On first server:
  `*/15 * * * * /opt/bonesync/bonesync.sh >>/var/log/bonesync.log 2>&1`

  * On 2nd server:
  `5-50/15`...

  * On 3rd server:
  `10-55/15`...
