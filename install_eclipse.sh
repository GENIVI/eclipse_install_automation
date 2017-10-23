#!/bin/bash
# (C) 2014 Gunnar Andersson
# License: MPLv2 - see project dir
# Git repository: https://github.com/gunnarx/franca_install_automation
# pull requests welcome

# --------------------------------------------------------------------------
# ECLIPSE INSTALLATION PART
# --------------------------------------------------------------------------

# Support 32 or 64 bit choice automatically
OSTYPE=$(uname -o)
MACHINE=$(uname -m)

# Check that a few necessary variables are defined
defined ECLIPSE_INSTALLER_$MACHINE ECLIPSE_INSTALL_DIR DOWNLOAD_DIR

# Create installation and workspace dirs
if [ -d "$ECLIPSE_INSTALL_DIR/eclipse" ] ; then
   if [ -z "$VAGRANT" ] ; then  # No need to warn in vagrant case
      echo
      echo "NOTE the eclipse installation dir exists ($ECLIPSE_INSTALL_DIR/eclipse)!"
      echo "It is usually not a problem but to make a clean install you may want to remove it"
      warn "Remove installation dir if you want to make a clean install."
   fi
fi

mkdir -p "$ECLIPSE_INSTALL_DIR" || die "Can't create target dir ($ECLIPSE_INSTALL_DIR)"

if [ $(/bin/ls "$ECLIPSE_WORKSPACE_DIR" 2>/dev/null | wc -l) -ne 0 ] ; then
   if [ -z "$VAGRANT" ] ; then  # No need to warn in vagrant case
      echo
      echo "NOTE the workspace dir in CONFIG exists ($ECLIPSE_WORKSPACE_DIR)!"
      echo "I will unpack a few example files into $ECLIPSE_WORKSPACE_DIR !"
      warn "If your workspace content is important you may want to back up your files!"
   fi
fi

mkdir -p "$ECLIPSE_WORKSPACE_DIR" || die "Fail creating $ECLIPSE_WORKSPACE_DIR"

if [ "$OSTYPE" = "GNU/Linux" -a "$MACHINE" = "i686" ]; then
    ECLIPSE_INSTALLER=$ECLIPSE_INSTALLER_i686
elif [ "$OSTYPE" = "GNU/Linux" -a "$MACHINE" = "x86_64" ]; then
    ECLIPSE_INSTALLER=$ECLIPSE_INSTALLER_x86_64
    # Future possibility: Handle MacOSX and others
else
    die "Sorry, unsupported OS or CPU architecture $OSTYPE:$MACHINE.  But you can probably fix this if you edit the script.  Pull requests welcome. "
fi

# Get Eclipse archive
section "Installing: Eclipse"
cd "$DOWNLOAD_DIR"
step "Downloading Eclipse installer"
download "$ECLIPSE_INSTALLER" $(deref ECLIPSE_MD5_$MACHINE) # This sets a variable named $downloaded_file

# Downloaded? - check MD5 and then unpack
[ -f "$downloaded_file" ] || die "ECLIPSE not found (not downloaded?)."
md5_check ECLIPSE "$downloaded_file" $MACHINE
step "Unpacking Eclipse to $ECLIPSE_INSTALL_DIR"
untar "$downloaded_file" "$ECLIPSE_INSTALL_DIR" || die

cd "$MYDIR"
