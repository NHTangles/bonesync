#!/bin/sh
DEBUG=0
TNNTVAR=tnnt/var
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
cd $MYCHROOT/$TNNTVAR
MYDATE=0
[ -s npcdata ] && MYDATE=`head -1 npcdata`
# rudimentary comment stripping
cat $REMOTES | cut -f1 -d'#' | grep -v '^\s*$' | while read TAG REMPATH
do 
    debug -n "$TAG: "
    [ "$TAG" = "$MYTAG" ] && debug "Ignoring local server."  && continue
    debug "$REMPATH/$TNNTVAR"
    [ -f npcdata.$TAG ] && mv npcdata.$TAG npcdata.$TAG.old
    $SCP $REMPATH/$TNNTVAR/npcdata npcdata.$TAG
    [ ! -f npcdata.$TAG ] && echo "Failed to get npcdata from $TAG" && continue
    if [ -s npcdata.$TAG ] 
    then
        NEWDATE=`head -1 npcdata.$TAG`
    else
        echo "WARNING: Empty npcdata from $TAG."
        NEWDATE=0
    fi
    if [ $NEWDATE -gt $MYDATE ]
    then
        echo "npcdata from $TAG ($NEWDATE) newer than local ($MYDATE) - replacing"
        MYDATE=$NEWDATE # So we don't copy it multiple times needlessly
        # Set perms first, so we don't try to read it before permissions are right.
        chown games:games npcdata.$TAG
        chmod 644 npcdata.$TAG
        [ -f npcdata ] && mv npcdata npcdata.old #mv will not disrupt open file descriptors
        mv npcdata.$TAG npcdata
    fi
done
debug $0 run ended at `date`
