#!/bin/bash

#  Tar2RPM - A Tar to RPM Converter
#  https://github.com/linuxlefty/tar2rpm
#  http://linuxlefty.com/linux/convert-tar-rpm-package.html
# 
#  Copyright (c) 2014 Peter Naudus
#  Licensed under the MIT license
#  See included LICENSE file

ARCH=''
DESCRIPTION=''
GROUP='Applications'
LICENSE='Restricted'
NAME=''
PRINTSPEC=false
RELEASE=$(date +%Y.%m.%d+%S)
SUMMARY=''
TARFILE=''
TARGET=''
URL=''
VERSION='1'
FILEPERM='-'
FILEUSER='root'
FILEGROUP='root'
AUTODEPS=false

function usage {
    echo "Usage: $0 [option1 ... optionN] <TARFILE.tar>"
    echo "  Required flags:"
    echo "      --target | -t <target>  The directory to extract the files into during installation."
    echo "                              Must be an absolute path"
    echo "  Optional flags:"
    echo "      --arch    | -a <arch>        The build architecture of the package."
    echo "                                   Default: autodetect"
    echo "      --descr   | -d <description> A longer description of the package. Default: <summary>"
    echo "      --group   | -g <group>       The group this package belongs to. Default: '$GROUP'"
    echo "      --license | -l <license>     The name of the lincense that governs use of this"
    echo "                                   software. Default: '$LICENSE'"
    echo "      --name    | -n <name>        The name of the package."
    echo "                                   Default: '<TARFILE>' (without the '.tar')"
    echo "      --release | -r <release>     The release number. Default: '$RELEASE'"
    echo "      --summary | -s <summary>     A description of the package."
    echo "                                   Default: 'Provides <NAME>'"
    echo "      --url     | -u <url>         A URI where more information on the package can be"
    echo "                                   found. Default: none"
    echo "      --version | -v <version>     The version number. Default: '$VERSION'"
    echo "      --fileperm | -o <fileperms>  The file permission mode. Default: '$FILEPERM'"
    echo "      --fileuser | -f <fileowner>  The files' owner. Default: '$FILEUSER'"
    echo "      --filegroup | -b <filegroup> The files' group. Default: '$FILEGROUP'"
    echo "      --autodeps | -A              Enable automatic dependency processing. Disabled by default"
    echo "  Misc:"
    echo "      --help Show this message"
    echo "      --print | -p Instead building the RPM, print the .spec file"
}

function spec {
    echo "Name: $NAME"
    echo "Summary: $SUMMARY"
    echo "Version: $VERSION"
    echo "Group: $GROUP"
    echo "License: $LICENSE"
    echo "Release: $RELEASE"
    echo "Prefix: $TARGET"
    echo "BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-$(whoami)-%(%{__id_u} -n)"
    if [ $AUTODEPS == false ]; then
        echo "AutoReqProv: no"
    fi
    if [ -n "$ARCH" ]; then
        echo "BuildArch: $ARCH"
    elif [ -n "$URL" ]; then
        echo "URL: $URL"
    fi
    echo
    echo "%description"
    echo $DESCRIPTION
    echo
    echo "%build"
    echo "cp $TARFILE %{_builddir}/archive.tar"
    echo
    echo "%install"
    echo "mkdir -p \$RPM_BUILD_ROOT$TARGET"
    echo "mv archive.tar \$RPM_BUILD_ROOT/archive.tar"
    echo "cd \$RPM_BUILD_ROOT$TARGET"
    echo "tar -xf \$RPM_BUILD_ROOT/archive.tar"
    echo "rm \$RPM_BUILD_ROOT/archive.tar"
    echo
    echo "%clean"
    echo "rm -fr \$RPM_BUILD_ROOT"
    echo
    echo "%files"
    echo "/"
    while IFS='/' read -ra pathSegments; do
        path=''
        for pathSegment in "${pathSegments[@]}"; do
            path="$path/$pathSegment"
            echo "$path"
        done
    done <<< $TARGET
    while IFS= read -ra fileNames; do
        for fileName in "${fileNames[@]}"; do
            echo %attr\($FILEPERM, $FILEUSER, $FILEGROUP\) \""$TARGET/${fileName#./}"\"
        done
    done <<< "$(tar -tf $TARFILE)"
}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --help)
            usage
            exit 0
            ;;
        -n|--name)
            NAME=$2
            shift
            ;;
        -s|--summary)
            SUMMARY=$2
            shift
            ;;
        -t|--target)
            TARGET=$2
            shift
            if [ "${TARGET:0:1}" != '/' ]; then
                usage
                echo "ERROR: target '$TARGET' is not an absolute path"
                exit 1
            fi
            ;;
        -v|--version)
            VERSION=$2
            shift
            ;;
        -a|--arch)
            ARCH=$2
            shift
            ;;
        -d|--descr)
            DESCRIPTION=$2
            shift
            ;;
        -g|--group)
            GROUP=$2
            shift
            ;;
        -l|--license)
            LICENSE=$2
            shift
            ;;
        -r|--release)
            RELEASE=$2
            shift
            ;;
        -u|--url)
            URL=$2
            shift
            ;;
        -o|--fileperm)
            FILEPERM=$2
            shift
            ;;
        -f|--fileuser)
            FILEUSER=$2
            shift
            ;;
        -b|--filegroup)
            FILEGROUP=$2
            shift
            ;;
        -A|--autodeps)
            AUTODEPS=true
            ;;
        -p|--print)
            PRINTSPEC=true
            ;;
        -*)
            usage
            echo "ERROR: '$1' is not a valid flag"
            exit 1
            ;;
        *)
            if [ -n "$TARFILE" ]; then
                usage
                echo "ERROR: Only one TARFILE can be specified"
                exit 1
            fi
            # Normalize path
            TARFILE=$(readlink -m "$1")

            # Do we have a tar file?
            if [ "${TARFILE##*.}" != 'tar' ]; then
                echo "ERROR: '$TARFILE' is not a tar file"
                exit 1
            fi

            # Does the file exist?
            if [ ! -f "$TARFILE" ];then
                echo "ERROR: '$TARFILE' does not exist"
                exit 1
            fi

            ;;
    esac
    shift
done

# Check for errors
if [ -z "$TARGET" ]; then
    usage
    echo "ERROR: --target | -t <target> is a required flag"
    exit 1
elif [ -z "$TARFILE" ]; then
    usage
    echo "ERROR: <TARFILE.tar> is a required argument"
    exit 1
fi

# Auto-populate optional fields
if [ -z "$NAME" ]; then
    NAME=$(basename "$TARFILE")
    NAME=${NAME%.*}
fi
if [ -z "$SUMMARY" ]; then
    SUMMARY="Provides $NAME."
fi
if [ -z "$DESCRIPTION" ]; then
    DESCRIPTION=$SUMMARY
fi

if $PRINTSPEC; then
    # Just print out the spec file
    spec
else
    # Build the RPM
    spec > /tmp/tar2rpm-$$.spec
    rpmbuild -bb /tmp/tar2rpm-$$.spec > /tmp/tar2rpm-$$.log 2>&1
    grep -i "Wrote:.*$NAME-$VERSION-$RELEASE.*rpm" /tmp/tar2rpm-$$.log
    if [ $? -gt 0 ]; then
        echo "ERROR: RPM build failed. Check log: /tmp/tar2rpm-$$.log Spec file: /tmp/tar2rpm-$$.spec"
        exit 1
    fi
    rm /tmp/tar2rpm-$$.spec
    rm /tmp/tar2rpm-$$.log
fi
exit 0
