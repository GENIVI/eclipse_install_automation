#!/bin/bash
# (C) 2014 Gunnar Andersson
# License: MPLv2 - see project dir
# Git repository: https://github.com/GENIVI/eclipse_install_automation
#                (https://github.com/gunnarx/franca_install_automation)
# pull requests welcome

# --------------------------------------------------------------------------
# functions.sh : HELPER FUNCTIONS SHARED BETWEEN ALL VARIANTS
# --------------------------------------------------------------------------

MD5SUM=md5sum   # On MacOS X, the binary is "md5"

debug() {
   $DEBUG && {
      printf '*DEBUG*: ' 1>&2
      echo $@ 1>&2
   }
}

die() {
   echo "Something went wrong.  Message: "
   echo "$@"
   [ -n "$ORIGDIR" ] && cd "$ORIGDIR"
   exit 1
}

# This function sets variable $VAGRANT if we are running under vagrant provisioning
test_vagrant() {
   VAGRANT=""
   echo "$0" | fgrep -q "vagrant-shell" && VAGRANT="yes"
}

# Run command only if Vagrant environment
if_vagrant() {
   [ -n "$VAGRANT" ] && eval $@
}

# Run command only if NOT Vagrant environment
unless_vagrant() {
   [ -z "$VAGRANT" ] && $@
}

# Print a section header
section() {
      # Using printf because "echo -n" is not fully portable
      printf '****************************************************************\n'
      printf '*** ' ; echo $@
      printf '****************************************************************\n'
}

# Print an operation with *** in front of it
step() {
      printf '*** ' ; echo "$@"
}

# Check condition is met or die
ensure() {
   $@ || die "Condition not met: $*"
}

# Check that variable(s) have been defined
defined() {
   for v in $* ; do
      [ -n "$v" ] || "Variable $v not defined in CONFIG?"
   done
}

# Print a warning and pause
# (it will not pause in Vagrant provisioning because there is no terminal)
warn() {
   echo "WARNING: $1"
   echo Hit return to continue
   unless_vagrant read
}

# Print a note, no pause
note() {
   echo "NOTE: $1"
}

# dereference variable:
# This is a kind of weird hack, but it evaluates the variable whose name is
# given by the input.  It is used extensively in this program.
# E.g.: If x=foo ; deref x returns foo and deref $x returns the value of $foo
deref() { eval echo \$$1 ; }

get_md5() {
   $MD5SUM "$1" | cut -b 1-32
}

match_md5() {
   f=$1
   expect_md5=$2
   if [ -z "$expect_md5" ] ; then
     echo "No MD5 defined - must assume it's OK"
     true
   elif [ "$(get_md5 $f)" = "$expect_md5" ] ; then
     true
   else
     false
   fi
}

md5_check() {
   item=$1
   file=$2
   arch=$3

   if [ -n "$arch" ] ; then
      wanted_md5=$(deref ${item}_MD5_${arch})
   else
      wanted_md5=$(deref ${item}_MD5)
   fi

   debug "Checking MD5 $wanted_md5 for $item"
   if match_md5 $file $wanted_md5 ; then
      echo "MD5 ok ($item)"
   else
      die "MD5 checksum ($md5) did not match predefined md5 ($wanted_md5) for item $item.  Check CONFIG file."
   fi
}

download() {
   cd "$DOWNLOAD_DIR"
   $DEBUG && set -x
   downloaded_file=
   outfile=$(basename "$1")
   expected_md5=$2

   if [ -n "$VAGRANT" ] ; then
      progress_flag="-q"     # Be absolutely quiet
   else
      progress_flag="-#"     # Use a small progress bar 
   fi

   # If exists in cache (and not in downloads), copy it from there
   if [ ! -f "$outfile" -a -n "$CACHE_DIR" -a -f "$CACHE_DIR/$outfile" ] ; then
      echo "Found in cache, copying..."
      cp "$CACHE_DIR/$outfile" "$outfile"
   fi

   # If already exists, we check md5 to know if it is complete and OK
   if [ -f "$outfile" ] ; then
      echo -n "File exists: $PWD/$outfile, checking..."
      if [ -n "$expected_md5" ] ; then
         if match_md5 $outfile $expected_md5 ; then
            echo "OK"
            downloaded_file="$outfile"
         else
            echo
            echo "File completeness check: expected MD5 $expected_md5 not matched"
         fi
      else
         echo "No MD5 given, can't check file completeness"
      fi
   else
      debug "File not downloaded yet"
   fi
   if [ -z "$downloaded_file" ] ; then
      echo Downloading...
#     wget -c "$1" -O "$outfile" -c --no-check-certificate || die "wget failed.  Is wget installed?"
      curl -L $progress_flag -O "$1"  || die "curl failed.  Is curl installed? (or is the network down?)"
      downloaded_file=$outfile
   fi
   $DEBUG && set +x
}

untar() {
   ensure [ -f "$1" ]
   targetdir="$2"
   # Use current directory as default targetdir if not specified
   [ -z "$targetdir" ] && targetdir=.
   tar xf "$1" -C "$2" || die "untar failed for $1"
}

# Check hash on update site such that an update is noticed
# (warning only)
check_site_hash() {
   url=$(deref ${1}_UPDATE_SERVER)
   hash=$(deref ${1}_UPDATE_SITE_HASH)
   debug "checking update site hash: $hash"
   curl -s "$url/" | grep -q "$hash" || warn "Site hash ($hash) not found on update site.  Probably it has been updated."
}

check_site_latest_version() {
   url=$(deref ${1}_UPDATE_SERVER)
   version=$(deref ${1}_VERSION)
   $DEBUG && {
      echo Listing all versions for your information:
      curl -s "$url/" | egrep '[0-9]\.[0-9]\.[0-9]' | sed 's/^/DEBUG: /'
   }

   latest=$(curl -s "$url/" | egrep '[0-9]\.[0-9]\.[0-9]' | sed 's/.*\([0-9]\.[0-9]\.[0-9]\).*/\1/' | sort -n | tail -1)
   debug "latest: $latest"
   if [ "$latest" != "$version" ] ; then
      note "There appears to be a later version than $version for $1, but you requested $version, so we mov e on."
   fi
}

# Calling Eclipse to install an update site, local or remote:
# http://stackoverflow.com/questions/7163970/how-do-you-automate-the-installation-of-eclipse-plugins-with-command-line
# http://help.eclipse.org/indigo/index.jsp?topic=%2Forg.eclipse.platform.doc.user%2Ftasks%2Frunning_eclipse.htm
# http://help.eclipse.org/helios/index.jsp?topic=/org.eclipse.platform.doc.isv/guide/p2_director.html
_install_update_site() {

   cd "$MYDIR"

   site="$(deref ${1}_UPDATE_SITE_URL)"
   features="$(deref ${1}_FEATURES)"

   debug "Installing from update site $1"

   $DEBUG && set -x

   $ECLIPSE_INSTALL_DIR/eclipse/eclipse -nosplash \
      -application org.eclipse.equinox.p2.director \
      -repository "$site" \
      -destination $ECLIPSE_INSTALL_DIR/eclipse \
      -installIU "$features"

   if [ $? -eq 0 ] ; then
      echo "Success"
   else
      echo "Fail"
      [ "$EXIT_ON_FAILURE" = "true" ] && exit 1  # <- needs to be set in environment
   fi

   $DEBUG && set +x
}

get_local_file() {
   cd "$MYDIR"
   file=$(deref ${1}_ARCHIVE)

   step "Find $file software archive locally"

   done=false

   # Location defined using environment variable?
   loc="$(deref ${1}_ARCHIVE_LOCAL_DIR)"
   if [ -n "$loc" ] ; then
      path="$loc/$file"
      if [ -f "$path" ] ; then
         echo "Found $file using \$${1}_ARCHIVE_LOCAL_DIR ($loc)"
         done=true
      fi
   else
      path="./$file"  # Let's try current directory, it might work
      if [ -f "$path" ] ; then
         echo "Found $file in current directory"
         done=true
      fi
   fi

   # If not found yet, ask user interactively
   while ! $done ; do
      echo "I need the file $file to be provided by you locally."
      echo "Please provide a path to the file (or the directory it is in)."
      echo "A path that is relative to current directory ($PWD) is OK."
      printf "Path: "
      read path
      [ -z "$path" ] && path="."
      path="${path/\~/$HOME}"  # We need to expand ~ manually
      [ -d "$path" -a -f "$path/$file" ] && path="$path/$file"
      [ -f "$path" ] && done=true
      [ ! -e "$path" ] && { echo "Let's see..." ; ls -l "$path" ; echo "No - try again." ; }
      [ -d "$path" -a ! -f "$path/$file" ] && { echo "No, can't find the file there - try again" ; }
   done

   cp "$path" "$DOWNLOAD_DIR"
   downloaded_file="$file"
   cd - >/dev/null
}

unpack_site_archive() {
   step "Unpacking archive $2 for $1"
   UNPACK_DIR=$DOWNLOAD_DIR/tmp.$$.$1
   mkdir -p "$UNPACK_DIR"            || die "mkdir UNPACK_DIR ($UNPACK_DIR) failed"
   cd "$UNPACK_DIR"                  || die "cd to UNPACK_DIR ($UNPACK_DIR) failed"
   unzip -q "$DOWNLOAD_DIR/$downloaded_file" || die "unzip $DOWNLOAD_DIR/$downloaded_file failed"
   cd - >/dev/null
}

install_site_archive() {
   section "Installing: $1 (site archive)"
   step "Downloading update site archive (.zip) for $1"
   url=$(deref ${1}_ARCHIVE_URL)
   download "$url" "$(deref ${1}_ARCHIVE_MD5)"
   md5_check "${1}_ARCHIVE" "$downloaded_file"
   _install_archive "$1"
}

install_online_update_site() {
   section "Installing: $1 (online site)"
   _install_update_site "$1"
}

_install_archive() {
   unpack_site_archive "$1" "$downloaded_file"
   step "Installing $1 from local update site (unpacked archive)"
   eval ${1}_UPDATE_SITE_URL="file://$UNPACK_DIR"
   _install_update_site "$1"
   cd "$MYDIR"
   rm -rf "$UNPACK_DIR"
}

install_local_file() {
   cd "$MYDIR"
   section "Installing local file for $1"
   archivefile=$(deref ${1}_ARCHIVE)
   get_local_file "$1"
   _install_archive "$1"
}

install() {
   # Which type of installation it is, is decided by which variables are
   # defined in CONFIG. Then call the corresponding installation function.
   if [ -n "$(deref ${1}_UPDATE_SITE_URL)" ] ; then
      install_online_update_site $1
   elif [ -n "$(deref ${1}_ARCHIVE_URL)" ] ; then
      install_site_archive $1
   else
      die "install(): For $1 I can find either ${1}_UPDATE_SITE_URL or ${1}_ARCHIVE_URL defined. Giving up."
   fi
}

try_cd() {
   if [ -z "$1" ] ; then
      die "try_cd: no directory given"
   else
      cd "$1" || die "cd to given dir $1 failed"
   fi
}


