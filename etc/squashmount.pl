#!/usr/bin/perl (this is only for editors)

# The tools which we have installed; if possible only the first in this list
# is used, but the others are a fallback if that fails.

@order = ('overlayfs', 'aufs', 'unionfs-fuse', 'unionfs', 'funionfs');

# Even if we define following is empty it is convenient to use
# this local variable throughout, so that we can simply change it:

my $defaults = {
	COMPRESSION => 'xz'
};

push(@mounts,
	&added_hash($defaults, {
		TAG => 'guest',
		DIR => '/home/guest',
		FILE => '/home/guest-skeleton.sqfs',
		KILL => 1 # normally remove data on every umount/remount
		# If you want to cancel this KILL temporarily
		# (e.g. to make modifications on guest-skeleton.sqsf)
		# use something like "squashmount --nokill set"
	}), &added_hash($defaults, {
		TAG => 'fixed',
		DIR => '/fixed/dir',
		FILE => '/fixed/content.sqfs',
		READONLY => 1 # Do not use overlayfs/aufs/...
	}), &added_hash($defaults, {
		TAG => 'db',
		DIR => '/var/db',
		FILE => '/var/db.sqfs',
		BACKUP => 1, # keep a backup in /var/db.sqfs.bak
		             # For a different path, we could have written:
		             # BACKUP => '/backup-disk/db.sqfs'
		CHANGES => '/var/db.changes',
		READONLY => '/var/db.readonly',

		# If /var is on a separate partition, we want that the
		# squashfile is first generated in /var/tmp:
		#TEMPDIR => '/var/tmp',

		# Do not resquash everytime but only after
		# 30 megabytes of fresh data:
		THRESHOLD => '30m',
		# Since this directory contains only very small files,
		# we cheat with this size by using that each file takes
		# at least a full block:
		# Hence, the number of files is more important for THRESHOLD
		# than their size. In gentoo, one installed package thus
		# "counts" about 2m in size
		# (although it is actually only 20 very short files):
		BLOCKSIZE => 65536
	}),
# Instead of specifying TAG, DIR, FILE, CHANGES explicitly,
# we use now that they are specified analogously to the above example
# with the standard_mount function.
	&standard_mount('kernel', '/usr/src', $defaults),
# The above is actually equivalent to
#	{ TAG => 'kernel', DIR => '/usr/src', FILE => '/usr/src.sqfs',
#	CHANGES => '/usr/src.changes', READONLY => '/usr/src.readonly' },

# We configure tex as in the "squashmount man" example:
	&standard_mount('text', '/usr/share/texmf-dist', $defaults, {
		DIFF => [
			qr{^ls-R$},
			qr{^tex(/generic(/config(/language(\.(dat(\.lua)?|def)))?)?)?$}
		]
	}),
	&standard_mount('portage', '/usr/portage', $defaults, {
		THRESHOLD => '80m'
	}),
	&standard_mount('games', '/usr/share/games', $defaults, {
		# games is huge: use the fastest compression algorithm for it.
		# (Note that this overrides $defaults):
		COMPRESSION => 'lzo'
	}),
	&standard_mount('office', '/usr/lib/libreoffice', $defaults)
);
