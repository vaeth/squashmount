# SPDX-License-Identifier: BSD-3-Clause
# find_cruft should ignore *.mount/{changes,readonly,workdir}
push(@cutre, '[^/]\.mount/(?:changes|readonly|workdir)$');
1;
