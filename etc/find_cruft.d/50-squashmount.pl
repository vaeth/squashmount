# find_cruft should ignore *.mount/{changes,readonly,workdir}
push(@cutre, '[^/]\.mount/(?:changes|readonly|workdir)$');
1;
