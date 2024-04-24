===================
Installation Manual
===================
.. include:: rstcommon.rst

Difficulty:
 - TODO

Table of Contents
-----------------
  * Dependencies
  * Compliling The Project

Dependencies
------------
Internally, project uses Nim compiler and the standard library.
For Installation Purposes, visit https://nim-lang.org/install.html

As of now, the only external dependency that project has is libmpv
any version which is not too old is supported, the stable or developement
version of api dont matter. (but it has to have mpv/client.h)

In some POSIX OSes (ArchLinux,BSDs..), the package manager does not provide
the library intact but only available as through installing mpv itself!

For Linux users, as distrobutions:
 Debian,Ubuntu-based::
   sudo apt install libmpv-dev

 ArchLinux-based::
   sudo pacman -S mpv

 Gentoo-based::
   sudo emerge --ask media-video/mpv

 Fedora-based::
   sudo dnf install mpv

 OpenSUSE-based::
   sudo zypper install mpv

 SlackWare(current)-based (slackel)::
   wget http://www.slackel.gr/repo/x86_64/current/slackel/extra/mpv-0.32.0-x86_64-3dj.txz
   sudo upgradepkg --install-new mpv-0.32.0-x86_64-3dj.txz

For Windows Users, mpv-1.dll is required for usage:
  - visit https://sourceforge.net/projects/mpv-player-windows/files/libmpv/
  - download the relevant archive for the given architecture.
  - unpack and place the dll where the executable (pnimrp.exe) is at.

For BSD Users,
  FreeBSD-based::
    sudo pkg install mpv

  OpenBSD-based::
    sudo pkg_add mpv

  NetBSD-based::
    pkgin install mpv

 For OpenSolaris/Illuminos-based::
   sudo pkg install mpv

For Information about supported platforms read user.rst
