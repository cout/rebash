Rebash -- a bash shell with ruby embedded
=========================================

Rebash is a simple C library which embeds a ruby interpreter inside the
bash shell.  This powerful construct allows various parts of bash to be
redefined or extended.

Currently the only supported extension is syntax highlighting for the
interactive shell.  To use it, build the extension:

    $ make -C ext/rebash

then run rebash:

    $ ./bin/rebash

Planned future features include modifying existing bash syntax, adding
new shell builtins, and a new function syntax which is half-bash and
half-ruby.  Of course, each of these features depends on how feasible
each one turns out to be.

