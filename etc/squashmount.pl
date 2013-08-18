#!/usr/bin/perl (this is only for editors)

# We use local variables to make the paths easily movable.

my $root = '';
my $portage = "$root/usr/portage";
my $tex = "$root/usr/share/texmf-dist";
my $db = "$root/var/db"

push(@mounts, {
	TAG => 'portage',
	DIR => $portage,
	CHANGES => "$portage.changes",
	READONLY => "$portage.readonly",
	FILE => "$portage.sqfs",
	TEMPDIR => "$root/tmp",
	THRESHOLD => "40m"
}, {
	TAG => 'tex',
	DIR => $tex,
	CHANGES => "$tex.changes",
	READONLY => "$tex.readonly",
	FILE => "$tex.sqfs",
	TEMPDIR => "$root/tmp",

	# This huge directory takes ages to compress with xz:
	COMPRESSION => 'lzo',

	# Ignore regeneration (with different timestampt of the files
	#     ls-R or tex/generic/config/language.*
	# Note that we also have to ignore changes in the parent directories:
	SKIP => [ '^tex$', '^tex/generic$', '^tex/generic/config$' ],
	DIFF => [ '^ls-R$', '^tex/generic/config/language\.(dat(|\.lua)|def)$' ]
}, {
	TAG => 'db',
	DIR => $db,
	CHANGES => "$db.changes",
	READONLY => "$db.readonly",
	FILE => "$db.sqfs",

	# Keep a bakup
	BACKUP => "$db.sqfs.bak",
	TEMPDIR => "$root/tmp"

	# A huge blocksize makes number of files more important than their size
	BLOCKSIZE => 65536,
	THRESHOLD => "2m"
});
