| Branch                              | Build Status   | Comments  |
| :---------------------------------- | :------------- | :-------- |
| **cpp_common_api_with_yocto_tools** | [![Build Status](https://travis-ci.org/GENIVI/eclipse_install_automation.svg?branch=cpp_common_api_with_yocto_tools)](https://travis-ci.org/GENIVI/eclipse_install_automation) | (recommended branch) |
| **master**                          | [![Build Status](https://travis-ci.org/GENIVI/eclipse_install_automation.svg?branch=master)](https://travis-ci.org/GENIVI/eclipse_install_automation) | (varying status - see below) |
| **ionas**                           | (No CI at the moment)  | AUTOSAR conversion tools. Unmaintained - feel free to investigate |
| *others*                            | (No CI at the moment)  | Work in progress |

Automated Eclipse/Franca environment installation
=================================================

Scripts related to [Franca IDL](https://github.com/franca/franca) installation.

VM or bare metal?
-----------------

If you are installing on your machine directly, use the
chapter "Installation on bare metal", after first reading
about the branches.

If you want to create a Virtual Machine read on.

Corporate Environment?
----------------------

If you are in an environment that requires web access through
a proxy, read the chapter Proxy Configuration.

A note on branches (for VM)
---------------------------

Before you create the VM there is a choice to make and that is which flavour
(distro) to use.  The git repository has a number of branches with minor
differences in the code but leading to quite big differences in the VM
(different distros and graphical environments).

UPDATE: Because there are differences in Franca and tool versions, these
branches now also modify what is installed in Eclipse.  All information
about the distro of course only applies only for the VM - if you install
locally you have your own distro chosen already.

### Branches / flavors:

The following branch installs C++ Common API support in addition to Franca.
Compatibility requires this to stay on an older Franca version.
* cpp_common_api_(with_yocto_tools)
 -- Ubuntu Trusty Tahr 14.04 LTS, with LXDE desktop and C++ Common API
 support (recommended).

The following branches install only Franca Tooling - the tip of the branch
is typically installing the latest Franca version.
* master          -- Ubuntu Trusty Tahr 14.04 LTS, with LXDE desktop (recommended)
* trusty64-unity  -- Ubuntu Trusty Tahr 14.04 LTS, with standard Ubuntu (Unity) desktop
                     (Warning: This is very big and takes a long time to
                      install. Also read KNOWN BUGS)

Experimental branches:
* ionas -- IONAS tooling for FRANCA/AUTOSAR(tm) integration
           *NOTE:* Using this requires some local archives that can only be
           downloaded using appropriate AUTOSAR/ARTOP accounts and
           memberships.

Branches named deprecated= are no longer kept up to date with changes,
and will likely be removed soon.

Branches named broken= are broken, probably for quite some time - because
if a break can be easily fixed it will be, and not renamed of course.

Branches not listed above are likely work-in-progress.  Try them only if
you need the very latest not yet merged functionality.

There are tags describing franca-version, eclipse-version, and operating
system, as well as *-stable tags

All VM images are x86 64-bit versions.

The stable tags are an easy way to get the latest stable, but generally
branches should be kept in working state, and the more specific tags are
also there only if that combination has been tested at least once.

LXDE desktops are lightweight.  Debian build is quick booting and lightweight
but lacks the nicer Virtualbox integration.  Ubuntu with LXDE is also
good and with full integration.

If you prefer, a full Ubuntu desktop is available but 14.04 with Unity is
heavier on resources.  The memory for this VM is set to 2.5GB as opposed to 1.5
on the others.  With that setting it runs alright.  Installation is _much_
slower though.

WARNING: There is a huge amount of packages being installed as part of
ubuntu-desktop, including things like LibreOffice... This flavor takes
a lot of time and bandwidth to initialize and is only recommended if you
really need it.

Better measurements would be nice but here follows the approximate _compressed_
sizes I could measure.  I did not at this time check the actual install size,
just a quick check of a gzipped version of the hdd image.

Note that this depends not only on the distro but more on how the provided
"base box" has been installed.  The base boxes can surely be optimized if
desired.

Gzipped hard disk image size:

* 1.3G  debian_7.3-lxde
* 886M  precise64-lxde
* 853M  trusty64-lxde
* 1.9G  trusty64-unity

### Sources:

The Ubuntu base systems are from Ubuntu's provided official "cloud" images.
These are from the current/ directory, so these are not guaranteed to be
unchanged.  They will be updated by Ubuntu, and hopefully will not break.
(Note however that the first time you run, you will download the
*current* latest copy, but after that Vagrant caches the base box for
you, so you will not get upstream changes unless you remove it from your
Vagrant setup)

Ubuntu images include Virtualbox guest additions (automatic window
resize etc.) which make the result nice to work with.

The Debian base system is fetched from Puppet Labs with a fixed version
number so presumably the system on this URL will not change, but it is
out of our hands.
This Debian image does not include the Virtualbox integration for
desktop/window resize, etc. (but the  shared folder functionality
apparently works, since it is required for Vagrant to work).


Instructions for Virtual Machine creation
-----------------------------------------

1. Install Vagrant. For example (for Debian or Ubuntu):
   ```bash
   $ sudo apt-get install vagrant
   ```
   or (for Fedora):
   ```bash
   $ sudo yum install vagrant
   ```
   Alternatively, download and install files from http://www.vagrantup.com/

2. Install VirtualBox. For example (for Debian or Ubuntu):
   ```bash
   $ sudo apt-get install virtualbox
   ```
   Alternatively, download and install files from http://www.virtualbox.org/

3. Run `vagrant up`:

   NOTE: I ran into a strange bug where a new machine claimed to be
   provisioned already (this should not happen...) but for that reason we
   can always give the explicit `--provision` flag.  It shouldn't be
   necessary, but it works so do it:
   ```bash
   $ vagrant up --provision
   ```

   The first time it will download the VM "base box" system from the URL.
   The base box is cached in your vagrant environment. (~/.vagrant
   currently)

   Feel free to add an alternative box of another distro, but the
   provisioning code that uses apt-get might need changes then.  Pull
   requests welcome.

   NOTE: There will be some errors towards the end of the provisioning
   which seem to be due to vagrant provisioning not running in a normal
   interactive shell. You can ignore those errors.  Of course you may have
   some other error that I have not seen yet, but using vagrant and a known
   base box this should be quite foolproof.

4. After provisioning, stop the VM which is now running headless.
   Update: Actually the gui=true flag is now in Vagrantfile.  Nonetheless,
   rebooting is recommended at this stage:

   ```bash
    $ vagrant halt
   ```

5. Then locate your VM in VirtualBox GUI and boot it normally

   You should soon see an graphical shell asking you to select user.

   Login as `vagrant`, password `vagrant`

6. Enjoy testing Franca environment!

   Use the default workspace directory at `/home/vagrant/workspace`.
   Just hit OK.

7. To run Franca examples you must manually import them into the workspace.

   The instructions can be found towards the end of `script.sh`.

Useful information about compatibility and versions:
https://github.com/franca/franca/wiki/Compatibility-Overview


Tweaking settings
------------------

   The VM is configured with 1.5 GB RAM (2.5 GB for Unity).  You may want to
   modify that setting in Vagrantfile or change the VM settings manually in
   VirtualBox if you are doing large builds.  I am not sure what is required
   except that 512MB was not enough, and 1.5GB worked for running Franca tests.

Sharing files
-------------

NOTE: In a Vagrant box you can share files through the /vagrant directory:

* On host: It is this directory, where you have Vagrantfile and this README.
* On Virtual Machine: Mounted at /vagrant

You can also get a direct command line on the VM using `vagrant ssh`, but
that's not too useful for running Eclipse:

```bash
    $ vagrant ssh
```

Read Vagrant documentation to learn more: http://www.vagrantup.com/

Installation on bare metal
--------------------------

You may use ./script.sh (and CONFIG) directly on any existing machine
(virtual or not) to simply automate the Franca installation.

1. Edit CONFIG if needed (but more typically simply check out the
   appropriate git branch)
2. Run script:

```bash
    $ ./script.sh
```

script.sh does not use any package manager so it should run on most distros. It
is developed on Fedora 23 but to some extent tested also on Ubuntu and
Debian (using the Vagrant method)

Prerequisites
-------------

script.sh does not install any packages except for Eclipse + Java packages so
for the non-Vagrant installation you need to manually install the needed
prerequisites on your machine.

This means JDK 7 as of now, but refer to official Franca documentation for
up to date information.  Install package java-1.7.0-openjdk on fedora or
openjdk-7-jre on Ubuntu or Debian.  (The vagrant script does this
automatically)

The script downloads and installs Eclipse.  If you have an Eclipse environment
already that you want to use, you probably need to instead follow a manual
procedure using Franca documentation to get Franca into your environment.

Proxy Configuration
-------------------

To update your vagrant environment you need first to update vagrant
to support using a proxy - you probably need to do this download also
through the proxy of course... ;-)

For example:

```bash
$ export http_proxy="http://user:password@your-proxy-host:port"
```
and then:

```bash
$ vagrant plugin install vagrant-proxyconf
```

Now vagrant can use a proxy for its http(s) access.

The Vagrantfile already includes support for copying settings from
your shell environment to the virtual environment when vagrant runs.
If http_proxy (and/or https_proxy) variables are defined as environment
variables in your shell, these will be carried over.

However, the final VM might need some adjustment if you expect it to work
with a proxy also.  This is currently out of scope but please report your
needs/findings and I'm sure we can find a solution.

In other words, simply define in your shell, before running vagrant up:
```bash
$ export http_proxy="http://user:password@your-proxy-host:port"
$ export https_proxy="http://user:password@your-proxy-host:port"
```

and so on.  The rest should follow.

There might be more information available in the documentation/support
channels of Vagrant-proxyconf plugin.


Development/Testing information
-------------------------------

Most users can disregard this.

Apart from corporate environments I use an http proxy for repeated testing.
By running a local caching proxy, the repeated downloads of files
(everything from eclipse, franca, and all the apt-get installs) can be
locally cached which speeds things up a lot, and reduces the load on
networks and servers provided by others!

Out of interest, from inside the VM, the host is the default gateway, so
here is a way to get the IP of the host:

```bash
$ netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10
```

But for now I simply have it hardcoded to 10.0.2.2 which appears to be
constant.  Presumably 10.0.2.x is a default adress scheme used by vagrant
for the NATed network of the VM.

Known bugs
----------

1. Not a bug in this project per se, but Franca 0.9.2 includes a bug that
   prevents the opening the Wizard for creating a new Franca file.
   For example by using "File->New Franca Interface"

   Workaround: Choose "File->New" instead and manually give it a .fidl suffix.
   Proceed editing as usual.

   http://code.google.com/a/eclipselabs.org/p/franca/issues/detail?id=149

2. There is an odd bug for Unity/Ubuntu Desktop only that causes the
   Eclipse menus to not display at all. It seems to happen on the first
   boot after installation (and never again!) It affects also the HUD.
   Simply closing and restarting Eclipse seems to solve the problem.  If
   you find any additional information, please feed it back.

Maintainer/Contact
-------------------
= Github account: gunnarx

