#!/bin/sh
# Set this to match the tag of the local server in the list below
MYTAG=hdf-eu
DEBUG=1
debug()
{
    [ "$DEBUG" = "0" ] || echo "$@"
}

RM="rm -f"
[ "$DEBUG" = "0" ] || RM="rm -v"

debug $0 run started at `date`
while read TAG REMPATH
do 
    debug tag $TAG
    [ "$TAG" = "$MYTAG" ] && debug "Ignoring local server."  && continue
    debug path $REMPATH
    [ -e bones.$TAG.txt ] && mv bones.$TAG.txt bones.$TAG.old
    scp $REMPATH/bones.txt bones.$TAG.txt
    # remote deletes.
    cat bones.$TAG.old bones.$TAG.txt bones.$TAG.txt | sort | uniq -u | while read SUM FN
    do
        # bones file consumed on remote.  Delete locally if we have the same one.
        debug "Consumed on remote: $FN ($SUM)"
        OURSUM=`md5sum $FN 2>/dev/null | cut -f1 -d' '` # empty string if $FN dne locally
        [ "$OURSUM" = "$SUM" ] && $RM "$FN"

    done
    # remote adds. Either new bones on remote, or possibly from us, or another remote
    # also filter anything in our local bones.txt, since we either already have it, or it was used locally.
    # or deleted earlier in this run
    cat bones.$TAG.old bones.$TAG.old bones.txt bones.txt bones.$TAG.txt | sort | uniq -u | while read SUM FN
    do
        debug "New: $FN ($SUM)"
        DN="`dirname $FN`"
        [ -d $DN ] || debug "No directory $DN - ignored." && continue

        # If the file dne locally, copy the remote one.
        # note that the game may have created a different file with the same name locally.
        # In this case, just keep the local.
        [ -e $FN ] || scp "$REMPATH/$FN" "$FN" && chown games:games "$FN"

    done
done <<REMOTES
hdf-eu nhsync@eu.hardfought.org:/opt/nethack/chroot
hdf-us nhsync@hardfought.org:/opt/nethack/hardfought.org
REMOTES
# finally, publish list of bones files on this server.
find . -type f -name 'bon[A-Z]*' -print | xargs md5sum > bones.txt
debug $0 run ended at `date`
