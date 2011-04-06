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

* currently have to way to update to the latest version of code
  previously fetched from the web, aside from manually deleting the
  cache directory

* default the common case that the source for hack "foo" is in
  "foo.arc"?
