#!/usr/bin/perl (this is only for editors)

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

# Even if we would not set anything in the following hash, it is recommended
# to use this local variable throughout, so that "defaults" for all mountpoints
# can be changed without modifying every mountpoint manually.

my $defaults = {
	COMPRESSION => 'xz' # We could actually omit this line as xz is default
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
		CHOWN => [ (getpwname('guest'))[2], # user and group of ...
			(getgrname('guest'))[2] ], # ... squashfile owner
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
	added_hash($defaults, {
		TAG => 'db',
		DIR => '/var/db',
		FILE => '/var/db.sqfs',
		BACKUP => 1, # keep a backup in /var/db.sqfs.bak
		             # For a different path, we could have written:
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
	standard_mount('tex', '/usr/share/texmf-dist', $defaults, {
		DIFF => [
			qr{^ls-R$},
			qr{^tex(/generic(/config(/language(\.(dat(\.lua)?|def)))?)?)?$}
		]
	}),
	standard_mount('portage', '/usr/portage', $defaults, {
		THRESHOLD => '80m',
		# Any change in the local/ subdirectory (except in .git,
		# profiles, metadata) should lead to a resquash, even if
		# the threshold is not reached:
		FILL => qr{^local/(?!(\.git|profiles|metadata)(/|$))}
	}),
	standard_mount('games', '/usr/share/games', $defaults, {
		# games is huge: use the fastest compression algorithm for it.
		# (Note that this overrides $defaults):
		COMPRESSION => 'lzo'
	}),
	standard_mount('office', '/usr/lib/libreoffice', $defaults)
);
