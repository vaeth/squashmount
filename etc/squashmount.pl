#!/usr/bin/perl (this is only for editors)

# To use squashmount, remove this comment and the following "print()" and
# "exit()" command from the file and write into the subsequent configuration
# of the variables (in particular of @mounts) what is approrpriate for
# your system!
#
# It is impossible to guess which mount-points you want and for which purpose;
# this default file contains just some examples showing what *might* be useful
# for you (and sometimes even only to demonstrate the syntax and some
# possibilities).
# Do not use it unchanged!
#
# Use "squashmount man" for further details and a full list of options
# (only a few are used in this file).
print(STDERR "The default /etc/squashmount.pl is only an example config!
It must be configured first for the mount-points you are actually using!
See 'squashmount man' and the comments in that file for how to do this.\n");
exit(1);

# First we specify the tools which we have (possibly) installed;
# if possible, only the first in this list is used, but the others are
# successively a fallback if that fails.
# The last fallback is automatically bind --mount
#
# In this example, we deviate from the defaults by changing some of the flags:
# We skip unionfs and funionfs tacitly unless *surely* available.
# (Note that if you compiled e.g. unionfs as a module but /proc/config.gz is
# not available this means that unionfs is not used even it could be).
#
# We also skip overlayfs if the module cannot be loaded successfully.
# Again, this means that overlayfs is skipped if compiled into the kernel.
# Use "overlayfs?" instead if you want a more reliable check for that case.

@order = qw(overlayfs aufs! unionfs-fuse! unionfs??# funionfs??#);

# The following variables all default to 1 (true).
# Uncomment the corresponding line if you want to have different defaults.
# Normally, this is not needed.
# $lazy = '';
# $squash_verbose = '';
# $locking = 1; # lock always, even for status and print-* commands
# $modprobe_squash = '';

# Do not override the default of $squashmount_quiet for a flexible config.
# For quicker execution, specify which version of mksquashfs is installed:
# $squashmount_quiet = 'qn-'; # if mksquashfs knows about -quiet
# $squashmount_quiet = 'rn+'; # if mksquashfs redirects progress to stderr
# $squashmount_quiet = 'n-';  # if <=mksquashfs-4.3 is unpatched
# $squashmount_quiet = 'r-n-r+n+';# for silent output only on terminals

# Unless you have a particular reason, it is wise to leave the choice
# of -processes and -mem to mksquashfs. So the default is '':
# $processors = '';
# $mem = '';

# The following is the default: If these files exist, we do not squash
# $killpower = [ '/etc/killpower', '/etc/nosquash' ]

# Even if we would not set anything in the following hash, it is recommended
# to use this local variable throughout, so that "defaults" for all mountpoints
# can be changed without modifying every mountpoint manually.

my $defaults = {
	COMPRESSION => 'xz', # We could omit this line as xz is default.
	                     # However, this might change in the future
	COMPOPT_LZ4 => '-Xhc', # We could omit this line as -Xhc is default
	COMPOPT_XZ => ['-Xbcj', 'x86'] # Use this in case COMPRESSION => 'xz'
};
my $non_binary = {
	COMPOPT_XZ => undef # "-Xbcj x86" is slower for pure text archives
};

# We use here the @mounts = ( ... ); syntax (do not forget the semicolon!)
# but we could use as well: push(@mounts, .... );
# The latter has the advantage that it can be used repeatedly to
# successively add mount-points.

@mounts = (
	# This first example does not honour anything set in $defaults:
	{
		TAG => 'fixed',
		DIR => '/fixed/dir',
		FILE => '/fixed/content.sqfs',
		READONLY => 1 # Do not use overlayfs/aufs/...
	},
	# To make $defaults effective, we use the added_hash() function:
	added_hash($defaults, {
		TAG => 'guest',
		DIR => '/home/guest',
		FILE => '/home/guest-skeleton.sqfs',
		CHMOD => 0400, # squashfile readonly by user
		CHOWN => [ (getpwnam('guest'))[2], # user and group of ...
			(getgrnam('guest'))[2] ],  # ... new squashfile's owner
		KILL => 1 # normally remove data on every umount/remount
		# If you want to cancel this KILL temporarily
		# (e.g. to make modifications on guest-skeleton.sqsf)
		# use something like "squashmount --nokill set"
	}),
	# The above block "added_hash(...)," is actually equivalent to
	# {
	#	COMPRESSION => 'xz',
	#	TAG => 'guest',
	#	DIR => '/home/guest',
	#	FILE => '/home/guest-skeleton.sqfs',
	#	KILL => 1
	# },
	# because added_hash() "adds" our values to that from $defaults.
	added_hash($defaults, $non_binary,  {
		TAG => 'db',
		DIR => '/var/db',
		FILE => '/var/db.sqfs',
		BACKUP => '.bak', # keep a backup in /var/db.sqfs.bak
		             # For an absolute path, we could have written:
		             # BACKUP => '/backup-disk/db.sqfs'
		CHANGES => '/var/db.changes',
		READONLY => '/var/db.readonly',

		# If /var is on a separate partition, you want probably that
		# the squashfile is first generated in /var/tmp so that it
		# can be moved without actually copying the data.
		# In this case, uncomment the following line:
		#TEMPDIR => '/var/tmp',

		# Do not resquash on every umount/remount but only when
		# 30 megabytes of fresh data are reached:
		THRESHOLD => '30m',
		# Since this directory contains only very small files,
		# we cheat with this size by using that each file takes
		# at least a full block:
		# Hence, the number of files is more important for THRESHOLD
		# than their size. In gentoo, one installed package thus
		# "counts" about 2m in size
		# (although it produces actually only 20 very short files):
		BLOCKSIZE => 65536
	}),
# Instead of specifying TAG, DIR, FILE, CHANGES explicitly,
# we use now that they are specified analogously to the above example
# with the standard_mount function:
	standard_mount('kernel', '/usr/src', $defaults),
# The above single line produces the equivalent of
#	added_hash({
#		TAG => 'kernel',
#		DIR => '/usr/src',
#		FILE => '/usr/src.sqfs',
#		CHANGES => '/usr/src.changes',
#		READONLY => '/usr/src.readonly'
#	}, $defaults),
# which in turn is effectively equivalent to
#	{
#		TAG => 'kernel',
#		DIR => '/usr/src',
#		FILE => '/usr/src.sqfs',
#		CHANGES => '/usr/src.changes',
#		READONLY => '/usr/src.readonly',
#		COMPRESSION => 'xz'
#	},

# We configure tex as in the "squashmount man" example:
	standard_mount('tex', '/usr/share/texmf-dist', $defaults, $non_binary, {
		DIFF => [
			qr{^ls-R$},
			qr{^tex(/generic(/config(/language(\.(dat(\.lua)?|def)))?)?)?$}
		]
	}),
	standard_mount('portage', '/usr/portage', $defaults, $non_binary, {
		THRESHOLD => '80m',
		# Any change in the local/ subdirectory (except in .git,
		# profiles, metadata) should lead to a resquash, even if
		# the threshold is not reached:
		FILL => qr{^local/(?!(\.git|profiles|metadata)(/|$))}
	}),
	standard_mount('games', '/usr/share/games', $defaults, {
		# games is huge: use the fastest compression algorithm for it.
		# (Note that this overrides $defaults):
		COMPRESSION => 'lz4',
		COMPOPT_LZ4 => ''
	}),
	standard_mount('office', '/usr/lib/libreoffice', $defaults, {
		# Make sure to use the algorithm with best compression ratio
		COMPRESSION => 'xz'
	})
);
