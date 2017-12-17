#!/bin/sh
# Set this to match the tag of the local server in the list below
MYTAG=hdf-eu

# Save deletions up until the end.
# In case one remote deleted a file and another still has it.
# this would appear like a new file if we already deleted it locally.
DELLIST=/tmp/bonesync.del.$$
> $DELLIST
while read TAG REMPATH
do 
    echo tag $TAG
    echo path $REMPATH
    [ "$TAG" = "$MYTAG" ] && continue
    [ -e bones.$TAG.txt ] && mv bones.$TAG.txt bones.$TAG.old
    scp $REMPATH/bones.txt bones.$TAG.txt
    # remote deletes.
    cat bones.$TAG.old bones.$TAG.txt bones.$TAG.txt | sort | uniq -u | while read SUM FN
    do
        # bones file consumed on remote.  Delete locally if we have the same one.
        echo "Consumed on remote: $FN ($SUM)"
        echo "$SUM $FN" >> $DELLIST
    done
    # remote adds. Either new bones on remote, or possibly from us, or another remote
    # also filter anything in our local bones.txt, since we either already have it, or it was used locally.
    cat bones.$TAG.old bones.$TAG.old bones.txt bones.txt bones.$TAG.txt | sort | uniq -u | while read SUM FN
    do
        # If the file dne locally, copy the remote one.
        # note that the game may have created a different file with the same name locally.
        # In this case, just keep the local.
        [ -e $FN ] || scp $REMPATH/$FN $FN && chown games:games $FN && echo "New: $FN ($SUM)"

    done
done <<REMOTES
hdf-eu nhsync@eu.hardfought.org:/opt/nethack/chroot
hdf-us nhsync@hardfought.org:/opt/nethack/hardfought.org
REMOTES
cat $DELLIST | while read SUM FN
do
    OURSUM=`md5sum $FN 2>/dev/null | cut -f1 -d' '` # empty string if $FN dne locally
    [ "$OURSUM" = "$SUM" ] && rm -v $FN
done
rm -f $DELLIST
# finally, publish list of bones files on this server.
find . -type f -name 'bon[A-Z]*' -print | xargs md5sum > bones.txt
