# squashmount

(C) Martin Väth (martin at mvath.de)

This project is under a BSD type license, meaning that you can do practically
everything with it except removing my name/copyright.

Init and management script for mounting rewritable squashfs-compressed data

This is the successor of the __squash_dir__ project
-	https://github.com/vaeth/squash_dir/

It is actually a ground-up rewrite of that project in perl with a
highly improved control interface.

One of its aims is to be init system independent.
For openrc and systemd ready-to-use init/service-files are provided;
I gladly add init-files for other init systems if I receive (tested) patches.

__squashmount__ works with systemd in “standard” setups, but due to
conceptional bugs of systemd in some setups (see section “Installation”),
systemd is no longer officially supported.

## What is this project?

This is __squashmount__, a generic initscript, user interface and management
tool for keeping directories compressed by squashfs but simultaneously keep
them writable using some of (depending on the configuration and what is
available):

-	overlay (AKA overlayfs for linux kernels 3.18 and newer)
-	overlayfs, a variant for older linux kernels, see
		http://git.kernel.org/?p=linux/kernel/git/mszeredi/vfs.git
-	aufs, see http://aufs.sourceforge.net
-	unionfs-fuse, see http://podgorny.cz/moin/UnionFsFuse
		(unionfs-fuse-0.25 or newer is required)
-	unionfs, see http://www.fsl.cs.sunysb.edu/project-unionfs.html
-	funionfs, see http://bugs.gentoo.org/show_bug.cgi?id=151673

Since __squashmount v15.0.0__ there is also a choice between

-	squashfs (the linux kernel module)
-	squashfuse, the fuse module, see https://github.com/vasi/squashfuse

The idea is that, as a rule, on shutdown the data is recompressed
(and the temporary modified data removed).
This approach is originally due to synss' script from
	http://forums.gentoo.org/viewtopic-t-465367-highlight-.html
In that forum thread you can also ask for help about this project.

For some mount points different rules than “resquash and delete on umount”
might be desired (see the examples section below), and moreover,
it might be necessary to override these rules temporarily.
For such things a powerful user interface is provided.

This project can be useful for any linux distribution.
Historically, the main motivations was to keep the Gentoo main repository
compressed. This is still one of the most striking examples:

If the Gentoo main repository (`/usr/portage` or `/var/db/repos/gentoo`)
is compressed with __squashmount__ (without `DISTDIR` which you should store
somewhere else when using this script), the required disk space is only
about 50-100 MB (depending on your compression method), instead of
200-400 MB (or much higher, the actual space requirement
depending essentially on the filesystem, e.g. how inodes are used).
Usually, also the access is much faster.

It is possible to combine __squashmount__ with portage's
`sync-type = squashdelta` to mount the Gentoo repository writable.

## Screenshot with a typical usage

![Demo screenshot](demo.svg?sanitize=true)

## Requirements

The script requires of course that squashfs support is activated in the
kernel (and supports the COMPRESSION method), that the mksquashfs tool
is available, and also that some of the above mentioned unionfs-type tools
is available and supported by the kernel.

## Warning

Since v17.0.0/v10.0.0 , __squashmount__ defaults to the COMPRESSION method
`zstd`/`lz4`. This method is available only in linux-4.14/3.19 or higher
or in squashfuse-0.1.101_alpha20170917/0.1.100_alpha20140523 or higher.
So take care to either use a sufficiently new kernel/squashfuse version
or to change the default!

Moreover, you need a decently new version of _perl5_ together with some of
its standard modules (which might need to be installed separately if your
_perl5_ version should be too old). Decently new perl versions should have the
`TERM::ANSIColor` module; you need this if you want to see nicely
colored output.

It is also strongly recommended to install the `File::Which` module
(although there are some fallbacks if it is not available).

If you want that the hard status line is set, also the title script from
https://github.com/vaeth/runtitle (version >=2.3) is required in your path.


## Installation

If you are a Gentoo user, you can just emerge __squashmount__ from the
__mv overlay__.

Otherwise you just have to copy `bin/squashmount` into `/usr/bin/squashmount`
or any other directory of your `$PATH`.
For zsh completion support also copy `zsh/_squashmount` into a directory of
your zsh's `$fpath`.

It is strongly recommended to put
-	`alias squashmount='noglob squashmount'`

into your `~/.zshrc` or `/etc/zsh/zshrc` or `/etc/zshrc`,
so that things like
-	`squashmount start *`

will work in your zsh as intended without the need to quote *.
(I assume that you do not use any poor shell instead of zsh.) ;)

If you use __revdep-rebuild__ from Gentoo or similar distributions, and
if you use the default naming schme, it is recommended to copy the content of
`etc/revdep-rebuild` into `/etc/revdep-rebuild` to cancel duplicate or obsolete
paths search of revdep-rebuild.

For __openrc__ support copy `openrc/init.d/squashmount` to
`/etc/init.d/squashmount` and activate it in the usual way.
For systemd-support copy `systemd/system/squashmount.service` to your
systemd unit folder (`pkg-config --variable=systemdsystemunitdir systemd`,
usually `/lib/systemd/system` or `/usr/lib/systemd/system`)
and activate it in the usual way (or e.g. copy into `/etc/systemd/system`)

If you use __systemd__ _be sure to compile the __mount__ binary
with __systemd__ support_
(this should be the case in most distributions providing systemd; in Gentoo
this means to enable `USE=systemd` for the util-linux package. If you compile
util-linux manually, make sure to pass `--with-systemd` to `./configure`).
In this case, __systemd__ will probably work for you in “standard” setups.
With __systemd-219__ (or newer?) and some unusual setups like `--make-shared`
on some partitions, it can happen nevertheless that __mount__ appears to work,
but actually nothing is mounted if __systemd__ is in use. This is related with
the fact that __systemd__ tries to control all mounts instead of letting the
kernel do it alone. Of course, this breaks tools like __squashmount__
completely.
Bug __systemd__ upstream about such problems, but not me: I am not planning
to add hacks to fix the breakage introduced by some ill-conceived __systemd__
concepts.

For __systemd__, you should set an appropriate timeout: There is no general
rule how long compression can take “maximally”, so the timeout is set to
infinity, by default. It is strongly recommended to set this to a realistic
value for you system and setting by giving a (generous) upper estimate for
your needs by copying the file `etc/system/squashmount.service.d/timeout.conf`
to `/etc/systemd/squashmount/service.d/timeout.conf` and editing appropriately.
If you copied the main script not to `/usr/bin/squashmount`, you should
put into the same directory a file with appropriate modified paths.
For instance, if you copied the main script to `/sbin/squashmount` then
create `/etc/systemd/system/squashmount.service.d/exec.conf` with the content
```
[Service]
ExecStart=
ExecStart=/sbin/squashmount start
ExecStop=
ExecStop=/sbin/squashmount -f --lsof=0 stop
```
Also copy `tmpfiles.d/squashmount.conf` to `/usr/lib/tmpfiles.d`, although this
is not absolutely necessary (squashmount will create the corresponding
directories anyway).
If you use an init-system which does not mount /run as a ramdisk,
you should cleanup /run/squashmount on every fresh start before
calling `squashmount start`.
Depending on your init-system, a way to achieve this might be to change the
first letter in the crucial line in `/usr/lib/tmpfiles.d/squashmount.conf`
from `d` to `D!` and to make sure that the processing of `/usr/lib/tmpfiles.d`
takes place before calling `squashmount start`.
(Since accidental cleaning can have very inconvenient consequences, and
currently only systemd supports the `D!` syntax, `d` is the default.)
See section __Emergency Case__ what to do if `/run/squashmount`
is removed accidentally anyway.
If you use `find_cruft`, you might want to copy the content of
`lib/find_cruft` to `/usr/lib/find_cruft` or `/etc` and adapt it to your needs.

If you plan to use portage's `sync-type = squashdelta`, you might want to copy
the content of `etc/portage/repo.postsync.d` to `/etc/portage/repo.postsync.d`
Note that the hook-file in this directory treats the mount point “gentoo”
specially! See the example configuration in `etc/squashmount.pl` how to
setup an appropriate mount point “gentoo” for this setting.

In all cases you have to copy `lib/squashmount.pl` to `/etc/squashmount.pl`
and adapt it to your need! This is an essential point of squashmount,
and it is impossible to use squashmount without setting up the configuration.
You can optionally also copy `lib/squashmount.pl` to `/lib/squashmount.pl` or
`/usr/lib/squashmount.pl` to provide a system-wide example config.
Alternatively, you can also modify that file to use it as a fallback if
`/etc/squashmount.pl` is not readable.


## Some Examples

Essentially, the init-system (or you) has to call
-	`squashmount start`

on start and
-	`squashmount -f --lsof=0 stop`

on shutdown (at a time when the local filesystems are already/still mounted).
The provided installation files for systemd and openrc do just this.

This will cause all configured mount points to be mounted/umounted
correspondingly. When umounting, by default the modified data is
recompressed into the squash-files (but this can be customized).

The configuration of the mount points happens in the file /etc/squashmount.pl
This is a perl file, so you can use perl code in this file to source other
files at your discretion.

The provided example configuration file etc/squashmount.pl is rather
realistic if you are a Gentoo user: It provides the following mount points

- (a)  guest:    A guest user's home directory /home/guest
- (b)  tex:      The installed files from texlive /usr/share/texmf-dist
- (c1) portage:  The Gentoo repository /usr/portage
- (c2) gentoo:   The Gentoo repository when using sync-type = squashdelta
- (d)  db:       The Gentoo database of installed packages /var/db

Further mount points are in the example config-file but not listed here.

For all the mount points it is reasonable to use squashmount with them for
different reasons:

- (a) The guest-user should be able to modify data in /home/guest, but its
changes should usually be forgotten. (Sometimes you will not want to
forget these changes, e.g. when you want to update the “default”
home directory which the user sees; see below how to do this).

- (b) The tex directory is huge, and it saves considerable space to keep it
compressed on disk.

- (c1) Keeping the Gentoo repository compressed does not only save an enormous
amount of disk space but actually also speeds up portage considerable,
because the disk access is faster on a single (squashed) file.
Moreover, after changes with eix --sync you might want to compare the
new files with previous versions in the squashed file which you can still
access when you use squashmount.

- (c2) When you prefer to use portage's `sync-type = squashdelta`, you already
have the advantage of a compressed portage tree. However, you might want to
use squashmount to make this portage tree writable (e.g. in order to
temporarily fix a broken Manifest file locally).

- (d) The db directory is short but its data is very sensible and the
number files is huge: Keeping it in a compressed file gives a lot
of disk space and speedup, and it makes sense to keep a compressed backup
of the last mounted version.

In these examples, additional features of squashmount are used in
the example configuration:

1. For (a), it is obviously necessary to use a different treatment:
Normally, the squash-file should not be generated, and the temporary data
should be removed.
A similar remark holds for (c2).

2. For (d), squashmount will keep a backup even of the squash-file for
the db directory.

3. squashing of (c1) and (d) should happen only when a certain
threshold of changes to the data is reached.
The modified data will survive the reboot even if it is not resquashed,
but it takes more diskspace of course, and there is no readonly version of
the corresponding files.

4. No resquash of the tex directory when only certain files (like the
automatically generated `ls-R` file) were updated:
In fact, if the only changes made to the directoy are in these files
(it is optionally also checked that their content is not changed),
the directory will be cleared when umounting/remounting/rebooting.

You can also call squashmount at runtime to resquash or clean certain
directories manually or to change states for the above “default” actions
on future umounts. For instance, if you changed the skeleton of the
guest user in (a) you can call
-	`squashmount --no-kill remount guest`

to force immediate regeneration of the squashed file from the directory.
Moreover, you can call squashmount to temporarily change the state of mounted
directories. For example, if you want to change temporarily that the guest
user's data is saved on remount, use
-	`squashmount --no-kill set guest`

A changed state will remain active until reset, restart, or stop is executed.
Another example: If a lot of data would be resquashed at the next umount,
but you want to reboot urgently, just call
-	`squashmount --no-squash set`

before rebooting.
Conversely, if you want to squash the portage mount point despite its
threshold is not reached (e.g. because you plan to make an experimental
change which you plan to undo later), you can call
-	`squashmount --squash restart portage`

If afterwards you made your experimental change and want to undo it, call
-	`squashmount --kill restart portage`

If your changes take a longer time and you want to make sure that you do not
forget to call the above command, you can temporarily change the state:
-	`squashmount --kill set portage`

Normally, this setting will survive a remount. In order to reset to the
original setting after remounting, use option `-r` with `remount`:
-	`squashmount -r remount portage`

This is the same as calling
-	```
	squashmount remount portage
	squashmount reset portage
	```

The above examples should perhaps be enough to give you an impression how
to use __squashmount__. To get an exact description of the user interface and
of the config file format just execute:
-	`squashmount man`


## Emergency Case

If you accidentally removed or corrupted `/run/squashmount`, e.g. due to a bug
in squashmount itself or in its configuration or if the init-system was
misconfigured and removed /run/squashmount after calling `squashmount start`,
you should try to umount unconditionally.
You can instruct squashmount to do this with
-	`squashmount -fI umount`

or (if you do not want resquashing in such a situation):
-	`squashmount -nfI umount`

This will work reliably unless you used temporary directories in your setup.
It will even work with temporary directories if their name is still stored
in /run/squashmount, i.e. if the information there was not lost completely.


## A Word of None-Warning

It is in general rather safe to squash a directory, even a rather vital one:
Even if e.g. you boot from a kernel which has no support for some of
__overlay__|__overlayfs__|__aufs__|__unionfs-fuse__|__unionfs__ |__funionfs__
to make the directory writable, __squashmount__ will mount it at least as
read-only (using `mount --bind` if necessary).
Moreover, if everything goes wrong you can still use the __unsquashfs__ tool
to unpack the directory manually.
Probably the only danger in packing “strange” directories are special files,
hard links (this information will usually get lost), or special devices
which are perhaps not supported by the used tools.


## Modules and Mounting

Since version 3.0, unless configured otherwise, __squashmount__ will attempt
to modprobe the modules
-	squashfs
-	aufs
-	fuse
-	overlay
-	overlayfs
-	unionfs

when they are required; optionally/alternatively, also the corresponding
kernel option can be checked in `/sys/module` or `/proc/config.gz`;
also the existence of required binaries can be checked before actually
the mounting is attempted.
It depends on your setting whether this is done and/or whether in case
of failure the corresponding tool is skipped tacitly without attempting
to mount.

If no tool mounts successfully, it is attempted to use `mount --bind` to get
the directory at least readonly on the expected place, so even in
this bad situation (which probably only happens if you boot from an
experimental kernel or a brand new kernel without corresponding support)
you can still access the directory read-only. Hence, also rather vital
directories can be compressed as long as it is not vital to write to them
(and as long as the relevant programs for mounting etc. are not contained
within these directories, of course).


## User Permissions

If you rely only on the tool squashfuse and either unionfs-fuse or funionfs
(which are all based on the fuse userspace file system), then
squashmount can also be used with user permissions.
To support selecting only these tools and appropriate files and dirs from
the calling user, the option `--user` is supported since squashmount v15.0.0.
For details, call `squashmount man` and look for the option --user.


## Recent squashfs-tools

It is recommended to use a new version than 4.3 of squashfs-tools which
has the `-quiet` option. Cf. the description of `--mksquash-verbose`
and the `$mksquash_verbose` variable in `./squashmount man` for details.
As a Gentoo user you can install such a recent version from the mv overlay.

However, this recommendation is only an eye-candy: `squashmount` will work
without any problems also with an unpatched version of `squashfs-tools`;
just the display when squashing will not be so nice.
