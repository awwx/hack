The hackinator is a system for resolving dependencies between
libraries using a declarative language outside of the libraries
themselves, instead of having the libraries declare their dependencies
with the usual "import" or "require" type statements.

The project is currently at an early pre-alpha stage under
development, so it isn't doing much useful yet.

This git repository is the source to the hackinator.  Since the
hackinator uses itself as its build system (how else?), the runnable
version which doesn't need the hackinator already installed can be
found at [hackbin](https://github.com/awwx/hackbin), as described
below in the installation instructions.


Installation
============

Racket
------

You will need [Racket](http://racket-lang.org/) installed.

* Go to the [download page](http://racket-lang.org/download/) and
  select your platform.  For Unbuntu, I choose "Ubuntu jaunty".

* It will download as a self-extracting shell script.  Run it with a
  command such as:

       sh racket-5.1-bin-i386-linux-ubuntu-jaunty.sh

* It will ask if you want a "Unix-style distribution", which splits
  the install into separate "bin", "usr", etc. directories.  You can
  use a Unix-style distribution if you want, but I say "no" here
  myself, which installs into a single directory.

* Next it will ask "Where do you want to install the 'racket'
  directory tree?".  You can put it wherever is most convenient for
  you; I'll often put it in my home directory with the version number
  by typing "~/racket-5.1".

* It will unpack, and then ask you if you want to install system
  links.  When I haven't created a Unix-style distribution, I'll just
  hit Enter here, which does the default of not installing links.

* Finally it will say "All done."

Now either add the `bin` directory in the install directory to your
PATH, or else create a symbolic link from a directory that is already in
your path to *install*/bin/racket.

To test, you should be able to type:

    racket -v

and see:

    Welcome to Racket v5.1.


hackinator
----------

Clone the runnable version of the hackinator:

    git clone git://github.com/awwx/hackbin.git

Then either add hackbin to your path, or else create a symbolic link
from a directory that is already in your path to hackbin/hack.

To test, you should be able to type:

    hack

and see:

    The hackinator is at your service.


Todo
====

* some less ridiculously naive resolution algorithm, once I have a
  clue as to what the problem domain looks like

* either accept a source code file being listed more than once in the
  recipe or at least display an understandable error instead of
  complaining about conflicting load order

* details of how to run Arc programs should be part of the recipe

* loading Arc files should be done with Arc's load

* currently have no way to update to the latest version of code
  previously fetched from the web, aside from manually deleting the
  cache directory

* default the common case that the source for hack "foo" is in
  "foo.arc"?

* earlier detection of refering to a hack or source file that doesn't
  exist

* I'm unclear on how to handle relationships between recipes.  For
  example, my lib/recipe depends on the Arc 3.1 recipe, and won't work
  without it, so it should have a reference to it.  On the other hand
  I may want to substitute my own different recipe for fulfilling the
  Arc prerequisite.

* I use ":" as the separator between the git revision and file path
  since that's what git uses in e.g. the git-show command; for
  consistency I should use a colon as the separator for tar files as
  well.

* explicitly specified files in assertions shouldn't need to be
  strings: currently `("/code/hack/notest.arc" provides aw/testing0)`
  works but `(/code/hack/notest.arc provides aw/testing0)` doesn't.
