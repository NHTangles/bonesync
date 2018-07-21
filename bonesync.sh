#!/bin/sh
DEBUG=0

bail()
{
    echo "$@" >&2
    exit 1
}

debug()
{
    [ "$DEBUG" = "0" ] || echo "$@"
}
# set up environment in bonesync.conf. Must reside in same dir as script.
MYDIR="$( cd "$(dirname "$0")" ; pwd -P )"
[ -s "$MYDIR/bonesync.conf" ] || bail "set local config in bonesync.conf"
. "$MYDIR/bonesync.conf"
SCP=scp
[ -z "$MYSSHKEY" ] || SCP="scp -i $MYSSHKEY"
[ -z "$MYTAG" ] && bail "set MYTAG to the tag of the local server."
[ -z "$REMOTES" ] && bail "set REMOTES to path of file containing remote servers."
[ -z "$MYCHROOT" ] && bail "set MYCHROOT to path of dgl chroot dir."

RM="rm -f"
[ "$DEBUG" = "0" ] || RM="rm -v"

debug ===================================
debug $0 run started at `date`
umask 007
cd $MYCHROOT
# rudimentary comment stripping
cat $REMOTES | cut -f1 -d'#' | grep -v '^\s*$' | while read TAG REMPATH
do 
    debug -n "$TAG: "
    [ "$TAG" = "$MYTAG" ] && debug "Ignoring local server."  && continue
    debug "$REMPATH"
    [ -f bones.$TAG.txt ] && mv bones.$TAG.txt bones.$TAG.old
    $SCP $REMPATH/bones.txt bones.$TAG.txt
    [ ! -f bones.$TAG.txt ] && echo "Failed to get bones from $TAG" && continue
    [ -s bones.$TAG.txt ] || echo "WARNING: Empty bones list from $TAG."
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
        if [ -d $DN ] ; then
            # If the file dne locally, copy the remote one.
            # note that the game may have created a different file with the same name locally.
            # In this case, just keep the local.
            [ -e $FN ] || ( $SCP "$REMPATH/$FN" "$FN" && chown games:games "$FN" )
        else
            debug "No directory $DN - ignored."
       fi
    done
done
# finally, publish list of bones files on this server.
find . -type f -name 'bon[A-Z]*' -print | xargs -r md5sum > bones.txt
debug $0 run ended at `date`
