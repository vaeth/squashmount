#!/usr/bin/perl (this is only for editors)

# As some first examples, we configure mount points "manually":

push(@mounts, {
	TAG => 'guest-user',
	DIR => '/home/guest',
	FILE => '/home/guest-skeleton.sqfs',
	KILL => 1 # normally remove data on every umount/remount
	# If you want to cancel this KILL temporarily
	# (e.g. to make modifications on guest-skeleton.sqsf)
	# use something like "squashmount --nokill set"
}, {
	TAG => 'fixed',
	DIR => '/fixed/dir',
	FILE => '/fixed/content.sqfs',
	READONLY => 1 # Do not use overlayfs/aufs/...: Non writable directory
}, {
	TAG => 'db',
	DIR = '/var/db',
	FILE = '/var/db.sqfs',
	BACKUP = '/var/db.sqfs.bak', # keep a backup
	CHANGES = '/var/db.changes',
	READONLY = '/var/db.readonly',

	# Do not resquash everytime but only after 30 megabytes of fresh data:
	THRESHOLD = '30m',
	# Since this directory contains only very small files, we cheat with
	# this size by using that each file takes at least a full block:
	# Hence, the number of files is more important for THRESHOLD than
	# their size. In gentoo, one installed package thus "counts" about
	# 2m in size (although it is actually only 20 very short files):
	BLOCKSIZE = 65536
});

# Other examples are generated with the provided standard_hash function:
# Recall that this function fills TAG, DIR, FILE, CHANGES, READONLY, and
# optionally also a BACKUP.

# For example, after the following commands, %db is the same hash as above:
my $root = '';
my %db = &standard_hash($root, '/var/db', 'db', 1);
$db{'THRESHOLD'} = $db{'THRESHOLD'} = '30m';
$db{'BLOCKSIZE'} = $db{'BLOCKSIZE'} = 65536; # about 2m per package

# We configure tex as in the "squashmount man" example:
my %tex= &standard_hash($root, '/usr/share/texmf-dist', 'tex');
$tex{'SKIP'} = $tex{'SKIP'} = '^ls-R$';
$tex{'DIFF'} = $tex{'DIFF'} = '^tex(/generic(/config(/language(\.(dat(\.lua)?|def)))?)?)?$';

my %portage = &standard_hash($root, '/usr/portage', 'portage');
$portage{'THRESHOLD'} = '40m';

my %kernel = &standard_hash($root, '/usr/src', 'kernel');
my %office = &standard_hash($root, '/usr/lib/libreoffice', 'office');
my %games = &standard_hash($root, '/usr/share/games', 'games');
$games{'COMPRESSION'} = 'lzo'; # games is a huge directory: compress it faster

# After we have defined all hashes, we tell squashmount to use them.
# We need of course not necessarily use the order in which the variables
# were defined:

push(@mounts,
# db is not pushed since this was configured earlier
	\%games,
	\%office,
	\%portage,
	\%tex,
	\%kernel
);
