============================================
pnimrp - Poor Man's radio Player in Nim-lang
============================================

are you on the terminal and want to listen to music without opening
the web browser?, We got you. with the collection of 30+ modifiable
radio station link files (json) you can select through the radio stations
and play, pause, mute, them without ever getting your hands dirty
touching on pls files.

with inspiration from `Poor Man's radio player <https://github.com/hakerdefo/pmrp>`_

| see doc/user.rst for a basic level user usage documentation.
| see doc/installation.rst for installation instructions.

Quick Installation
------------------
first install mpv for your distrobution (it must be the developmental version).

then please install the `Nim compiler <https://nim-lang.org/install.html>`_
  - unix::
     curl https://nim-lang.org/choosenim/init.sh -sSf | sh
  - Windows::
      please see the choosenim ` releases <https://github.com/dom96/choosenim/releases>`_
  - or figure it out yourself(gentoo chads report in)::
    `Nim compiler <https://nim-lang.org/install.html>`_

After installing the compiler run::
  nimble install pnimrp
or to compile from here::
  nim c pnimrp
  ./pnimrp

What we solve for you
---------------------
Disadvantages of pmrp::
  - pmrp is not portable (windows)
  - it is hard to hunt down links and edit them
  - there is no way to check if the link is dead
  - the source code is very redundant and repetitive

what we give you::
  - we solve all of that
  - you get the now playing song
  - its easier to develop in

Do you want to readme(read me) in html?
---------------------------------------
documentation is written in RST so these can be viewed in a typical
text editor or can be used to generate HTML source by running::
  nim rst2html file.rst

then use a web browser to open htmldocs/file.html

Cites
-----
- pmrp -> https://github.com/hakerdefo/pmrp
   code was referenced and links were used.

- libmpv -> https://github.com/mpv-player/mpv
   api library was used for playback.

- c2nim -> https://github.com/nim-lang/c2nim
   helped wrapping objects.

Thanks
------
- hundreds of other people from which this code base was made
  possible from.
  - Nim forums -> forum.nim-lang.org
  - stackoverflow
  - github sources (mpv, other radio players)
  - chatgpt 3.5
  - everybody else
