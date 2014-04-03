Tar to RPM Converter
=====================

This script accepts a tarball and then creates an RPM packge from it

First things first
------------------

Before you use this nifty script, you'll have to set up your environment:

Install `rpmbuild`
:   Install whatever packages you need to in order to get the `rpmbuild` executable. If you're using [Arch][], all packages you need are in in the [AUR][], just read the comments as the `PKGBUILD` for [beecrypt][] needs to be slightly modified

Setup a working directory for `rpmbuild`
:   `rpmbuild` needs a working directory with specific subdirectories to build packages in. Use the following command to create the directory (obviously `<WORKING_DIR>` with the directory of your choice): `mkdir -p <WORKING_DIRECTORY>/{BUILD,RPMS,SOURCES,SPECS,SRPMS}`

Define a working directory for `rpmbuild`
:   edit `~/.rpmmacros` and define `%_topdir` to be your working directory. The syntax (all one line) is: `%_topdir <WORKING_DIRECTORY>`


[Arch]: wp:Arch_Linux
[AUR]: http://aur.archlinux.org/
[beecrypt]: http://aur.archlinux.org/packages.php?ID=16387

Using tar2rpm.sh
----------------

### Most basic usage ###

You have file `my_project.tar` and you want an rpm that installs it to `/home/httpd/myProject`

    tar2rpm.sh my_project.tar --target /home/httpd/myProject

### Advanced usage ###

Same as above, but now you want to specify a summary, version number and release number in the RPM

    tar2rpm.sh my_project.tar --target /home/httpd/myProject
                              --summary "LinuxLefty core web application"
                              --version T1000 --release dailyBuild-1339158942

### Spec building usage ###

Same as above, but instead of actually building the RPM, output a SPEC file so you can customize it before building<

    tar2rpm.sh my_project.tar --target /home/httpd/myProject
                              --summary "LinuxLefty core web application"
                              --version T1000 --release dailyBuild-1339158942
                              --print > my_project.spec
