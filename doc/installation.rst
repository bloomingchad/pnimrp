===================
Installation Manual
===================

Difficulty:
 - TODO

Table of Contents
-------------------
  * Dependencies
  * Compliling The Project
  * Using PreComplied Packages

Dependencies
------------
Internally, project uses Nim compiler and the stamdard library.
For Installation Purposes, visit https://nim-lang.org/install.html

As of now, the only external dependency that project has is libmpv
any version which is not too old is supported, the stable or developement
version of api dont matter.

In some POSIX OSes (ArchLinux,BSDs..), the package manager does not provide
the library intact.while its only available through installing mpv itself!

For Linux users, per distrobutions:

Debian,Ubuntu-based:
 ```
  sudo apt install libmpv-dev
 ```

ArchLinux-based:
 ```
  sudo pacman -S mpv
 ```

Gentoo-based:
 ```
 ```

RHEL, Fedora-based:
 ```
 ```

OpenSUSE-based:
 ```
 ```

SlackWare-based:
 ```
 ```

For Windows Users, mpv-1.dll is required for usage:
 - visit https://sourceforge.net/projects/mpv-player-windows/files/libmpv/
 - download the relevant archive for the given architecture.
 - unpack and place the dll where the executable (pnimrp.exe) is at.

For BSD Users,
 FreeBSD-based:
  ```
   sudo pkg install mpv
  ```
 OpenBSD,NetBSD-based:
  ```
  ```

For OpenSolaris/Illuminos-based:
 ```
 ```

For Information about supported platforms read user.rst

Compiling The Project
---------------------
Compilation is as simple as running this command at root project folder,
and is the same regardless the platform.

Using Nimble Package Manager:
 ```
  nimble build
 ```
Using Compiler Directly:
 ```
  nim c -d:release -o:pnimrp src/pnimrp
 ```
or using the shell script provided for POSIX Users:
 ```
  ./releaseBuild.sh
 ```

Using PreComplied Packages
--------------------------
* Packages need to be made available yet!
