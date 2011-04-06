This is the source to the hackinator.  Since the hackinator uses
itself as its build system (how else?), see
[hackbin](https://github.com/awwx/hackbin) for the runnable version
produced by running `hack` on `hackinator.recipe`.


Todo
----

* some less ridiculously naive resolution algorithm, once I have a
  clue as to what the problem domain looks like

* details of how to run Arc programs should be part of the recipe

* loading Arc files should be done with Arc's load

* git repos would be better downloaded with git clone instead of http

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
