#!/usr/bin/perl (this is only for editors)

# To use squashmount, remove this comment and the following "fatal()"
# command from the file and write into the subsequent configuration
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
fatal('The default /etc/squashmount.pl is only an example config!',
'It must be configured first for the mount-points you want.',
'See "squashmount man" and the comments in /etc/squashmount.pl');

# The configuration might depend on the hostname: Test the variable $hostname
# to use the same file for different configs on different machines.
# (We do not employ this possibility in this example file).
# The followng line initializes $hostname appropriately:
# use Sys::Hostname;
# my $hostname = ($ENV{'HOSTNAME'} // hostname());

# First we specify the tools which we have (possibly) installed;
# if possible, only the first in this list is used, but the others are
# successively a fallback if that fails.
# The last fallback is automatically bind --mount
#
# In this example, we deviate from the defaults by changing some of the flags:
# We skip unionfs and funionfs tacitly unless *surely* available.
# (Note that if you compiled e.g. unionfs as a module but /proc/config.gz is
# not available this means that unionfs is not used even if it could be).
#
# We also skip overlay and overlayfs if the module cannot be loaded
# successfully. Note again that this means that overlayfs is skipped
# if compiled into the kernel. Use "overlay? overlayfs?" instead
# if you want a more reliable check for that case.

@order = qw(overlay overlayfs aufs! unionfs-fuse! unionfs??# funionfs??#);

# Set $obsolete_overlayfs = 1 if you normally use a kernel older than 3.15.
# Set $obsolete_overlayfs = undef if you only use >=kernel-3.15
# Set $obsolete_overlayfs = 'force' if you never use overlayfs or
# never use >=kernel-3.15 (and <kernel-3.18)
# Leave the default ($obsolete_overlayfs = '') if it might happen that
# you sometimes use kernels between 3.15 and (less than) 3.18 and
# also want a fallback for older kernels.
#$obsolete_overlayfs = 1;

# The following variables all default to 1 (true).
# Uncomment the corresponding line if you want to have different defaults.
# Normally, this is not needed.
# $lazy = '';
# $squash_verbose = '';
# $modprobe_loop = '';
# $modprobe_squash = '';

# Uncomment the following if you prefer (globally) resquashing on start
# instead of resquashing on umount/stop. You can override this individually
# per mount-point by setting RESQUASH_ON_START for that mount-point:
# $resquash_on_start = 1; # the default is ''

# Uncomment the following line if you do not want to remove /run/squashmount
# on "squashmount stop". The default is 1 which means to remove it if empty
# (but not its parent directories). You can also specify a negative number
# to remove all its empty parent directories or a positive number + 1 for
# the number of parent directories to remove.
# $rm_rundir

# Specify the default for RM_DIR, RM_CHANGES, RM_WORKDIR, RM_READONLY.
# The number has the analogous meaning to $rm_rundir for the corresponding
# directories.
# $rm_dir = 0; # This is the default
# $rm_changes = $rm_workdir = $rm_readonly = 1; # This is the default.
# Unless you use temporary directories (not recommended),
# you will probably want to keep the created directories:
$rm_changes = $rm_workdir = $rm_readonly = 0;

# The default of $locking depends on the command used.
# Normally, there is no reason to uncomment the following line:
# $locking = 1; # lock always, even if it appears unnecessary

# Do not override the default of $squashmount_quiet for a flexible config.
# For quicker execution, specify which version of mksquashfs is installed:
# $squashmount_quiet = 'qn-'; # if mksquashfs knows about -quiet
# $squashmount_quiet = 'rn+'; # if mksquashfs redirects progress to stderr
# $squashmount_quiet = 'n-';  # if <=mksquashfs-4.3 is unpatched
# $squashmount_quiet = 'r-n-r+n+';# for silent output only on terminals

# Unless you have a particular reason, it is wise to leave the choice
# of -processors and -mem to mksquashfs. So the default is '':
# $processors = '';
# $mem = '';

# The following is only needed if you want/need to hack umount options.
# The following lines add option -i unless something was passed by
# --umount or --umount-ro, respectively (in which case nothing is added).
# push(@umount, '-i') unless(@umount);
# push(@umount_ro, '-i') unless(@umount_ro);

# The following is the default: If these files exist, we do not squash
# $killpower = [ '/etc/killpower', '/etc/nosquash' ]

# Even if we would not set anything in the following hash, it is recommended
# to use this local variable throughout, so that "defaults" for all
# mount-points can be changed without modifying every mount-point manually.

my $defaults = {
	COMPRESSION => 'lz4', # We could omit this line as lz4 is default.
	COMPOPT_LZ4 => '-Xhc', # We could omit this line as -Xhc is default
	# In case of COMPRESSION => 'xz', we use the following option.
	# Note that this option roughly doubles the squashing time for only
	# slightly better compression of binaries.
	COMPOPT_XZ => ['-Xbcj', 'x86']
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
		FILE => '/fixed/content.sfs',
		READONLY => 1 # Do not use overlayfs/aufs/...
	},
	# To make $defaults effective, we use the added_hash() function:
	added_hash($defaults, {
		TAG => 'guest',
		DIR => '/home/guest',
		FILE => '/home/guest-skeleton.sfs',
		CHMOD => 0400, # squashfile readonly by user
		CHOWN => [ (getpwnam('guest'))[2], # user and group of ...
			(getgrnam('guest'))[2] ],  # ... new squashfile's owner
		KILL => 1, # normally remove data on every umount/remount
		# Clean temporary directories, independent of defaults:
		RM_CHANGES => 1, RM_WORKDIR => 1, RM_READONLY => 1,
		# If you want to cancel this KILL temporarily
		# (e.g. to make modifications on guest-skeleton.sqsf)
		# use something like "squashmount --nokill set"
		# In such a case, we must no postpone resquashing
		# even if $resquash_on_start should be true, becuse
		# CHANGES is a temporary directory:
		RESQUASH_ON_START => ''
	}),
	# The above block "added_hash(...)," is actually equivalent to
	# {
	#	COMPRESSION => 'xz',
	#	TAG => 'guest',
	#	DIR => '/home/guest',
	#	FILE => '/home/guest-skeleton.sfs',
	#	KILL => 1,
	#	RESQUASH_ON_START => ''
	# },
	# because added_hash() "adds" our values to that from $defaults.
	added_hash($defaults, $non_binary,  {
		TAG => 'db',
		DIR => '/var/db',
		FILE => '/var/db.mount/db.sfs',
		BACKUP => '.bak', # keep a backup in /var/db.mount/db.sfs.bak
		             # For an absolute path, we could have written:
		             # BACKUP => '/backup-disk/db.sfs'
		CHANGES => '/var/db.mount/changes',
		WORKDIR => '/var/db.mount/workdir',
		READONLY => '/var/db.mount/readonly',

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
#		FILE => '/usr/src.mount/src.sfs',
#		CHANGES => '/usr/src.mount/changes',
#		WORKDIR => '/usr/src.mount/workdir',
#		READONLY => '/usr/src.mount/readonly'
#	}, $defaults),
# which in turn is effectively equivalent to
#	{
#		TAG => 'kernel',
#		DIR => '/usr/src',
#		FILE => '/usr/src.mount/src.sfs',
#		CHANGES => '/usr/src.mount/changes',
#		WORKDIR => '/usr/src.mount/workdir',
#		READONLY => '/usr/src.mount/readonly',
#		COMPRESSION => 'xz'
#	},
# (the WORKDIR is omitted if $no_workdir = 1 is set)

# We configure tex as in the "squashmount man" example:
	standard_mount('tex', '/usr/share/texmf-dist', $defaults, $non_binary, {
		DIFF => [
			qr{^ls-R$},
			qr{^tex(?:/generic(?:/config(?:/language(?:\.(?:dat(?:\.lua)?|def)))?)?)?$}
		]
	}),
	standard_mount('portage', '/usr/portage', $defaults, $non_binary, {
		# We know that no hardlinks or similar "tricky" things are used
		# in the portage tree, hence we "can" omit the umount helpers
		# of e.g. aufs. (This is only an example! Use this only if you
		# have problems and understand what you are doing; usually,
		# there is no reason to omit the umount helpers!)
		# In the following example, we use -i if nothing is passed
		# through --umount (or through the setting of @umount above).
		# *If* --umount is specified, we do not define UMOUNT, i.e.
		# the default value (the passed options) is chosen.
		UMOUNT => ((@umount) ? undef : '-i'),
		# It is reasonable to not recompress the directory always:
		THRESHOLD => '80m',
		# Any change in the local/ subdirectory (except in .git,
		# profiles, metadata) should lead to a resquash, even if
		# the threshold is not reached:
		FILL => qr{^local/(?!(?:\.git|profiles|metadata)(?:/|$))}
	}),
	standard_mount('games', '/usr/share/games', $defaults, {
		# games is huge: use the fastest compression algorithm for it.
		# (Note that this possibly overrides $defaults):
		COMPRESSION => 'lz4',
		COMPOPT_LZ4 => ''
	}),
	standard_mount('office', '/usr/lib/libreoffice', $defaults, {
		# Make sure to use the algorithm with best compression ratio,
		# possibly overriding $defaults:
		COMPRESSION => 'xz'
	})
);


# Now we give an example of a mount-point "custom" which is only available
# if a corresponding path to a squash file was passed with the option
# --arg=file (or -a file).

# This is the "luxury" variant of the code described with "squashmount man".

# We use the variable "$custom" to indicate whether the mount-point is visible.
# By default, it is only visible if an option was passed with --arg:

my $custom = @ARGV;
my $file = undef;
if($custom) {
	$file = pop(@ARGV);
	fatal("argument '$file' of --args is not a file") unless(-f $file);

	# If B<--args> was provided once, store it for later usage
	$locking = $storing = 1 # don't set $storing without $locking!
}

# The following is important:
# The mount-point should always be visible if there is data stored for it
# in $rundir. This is important so that when the init-system calls
# "squashmount stop", this will properly shut down the mount-point
# (even if the special option --arg=something does not occur in this command.)
# This also has the nice side effect that the mount-point will appear
# with "squashmount list", once it is mounted.

$custom ||= have_stored_data('custom');

# Uncomment, if you want to hide "custom" only for "squashmount start":
# $custom ||= ($command ne 'start');

# Uncomment, if you want to make "custom" visible to all query commands like
# "squashmount list" or "squashmount print-...":
# $custom ||= $storing;

# We use a callback function to store/restore $file:

$before = sub {
	# These are the 3 parameters provided to callback functions:
	my ($mountpoint, $store, $config) = @_;

	# Handle only that mount-point which is of interest for us:
	return 1 unless($mountpoint eq 'custom');

	my $stored = $store->{FILE};

	if(defined($stored)) {
		if(defined($file) && ($stored ne $file)) {
			error("stored path $stored",
			"differs from --arg $file",
			'Use "squashmount stop|forget custom"');
			# We return a false value to skip the action:
			return ''
		}
	} else {
		# Store $file for future usage:
		$store->{FILE} = $stored = $file
	}
	# Note that $stored is undefined here if no data was stored and
	# if no --arg argument was provided

	# Use the stored value as the configuration value for FILE
	# (provided $stored is defined; if it undefined do not touch anything)
	$config->{FILE} = $stored if(defined($stored));

	1 # return a true value!
};

# Finally, we make the mount-point available if $custom is true

push(@mounts, # append the following to @mounts:

# In this example, we use /var/custom as DIR, and
# /var/custom.mount/{readonly,changes,workdir} as READONLY,CHANGES,WORKDIR.
# Since almost everything is the setting of "standard_mount", we only
# need to override FILE:
	standard_mount('custom', '/var/custom', {
		# if $file is undefined, we use some "dummy" path instead
		# (it should be an absolute path to avoid error messages)
		FILE => ($file // '/default.sfs')
	})
# now we finish the above push command, indicating that this push command
# should be executed only if $custom is true:
) if($custom);


1;  # The last executed command in this file should be a true expression
