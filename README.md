The GNAT Components Collection (GNATCOLL) - DB
==============================================

This is the DB module of the GNAT Components Collection. Please refer to
individual components for more details.

Dependencies
------------

This module depends on the following external components, that should be
available on your system:

- gprbuild
- gnatcoll-core
- As well as relevant third-party libraries required by components.

Configuring the build process
-----------------------------

The following variables can be used to configure the build process:

General:

   prefix     : location of the installation, the default is the running
                GNAT installation root.

   BUILD      : control the build options : PROD (default) or DEBUG

   PROCESSORS : parallel compilation (default is 0, which uses all available
                cores)

   TARGET     : for cross-compilation, auto-detected for native platforms

   SOURCE_DIR : for out-of-tree build

   INTEGRATED : treat prefix as compiler installation (yes/no)
                this is so that installed gnatcoll project can later be
                referenced as predefined project of this compiler;
                this adds a normalized target subdir to prefix
                default is "no"

Module-specific:

   Please refer to individual components.

To use the default options:

   $ make setup

Building
--------

The components of GNATCOLL DB Module are built using standalone GPR
project files, to build each of them is as simple as:

$ gprbuild gnatcoll-<component>.gpr

However, to build all versions of the library (static, relocatable and
static-pic) it is simpler to use the provided Makefiles:

$ make -C <component>

Then, to install it:

$ make -C <component> install


Bug reports
-----------

Please send questions and bug reports to report@adacore.com following
the same procedures used to submit reports with the GNAT toolset itself.
