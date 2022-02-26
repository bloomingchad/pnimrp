======================
User Manual for PNimRP
======================
.. include:: rstcommon.rst

Table Of Contents
-----------------
  * Supported Platforms
  * Controls
  * Links
  * Qoutes

Supported Platforms
-------------------
Ceiling of supportiveness boils down to the usage of audio api used
to play streams,and not because of the application code, thus can be
extended in the future

Supported platforms include but not limited to:
 - Working
  * Windows 7+
  * MacOS
  * Linux 3.2+
  * BSDs

DragonFlyBSD is not currently supported as the standard library is too buggy
for it (as in tty).

Controls
--------
General Controls are using given numbers or characters to select the menu.
where R would return and q would quit out of the application.
and when stream is being played, use p to pause/mute or play.

Links
-----
Editing Links is just to look at the relevant file in assets directory.
the files are arranged in an json array and has to be even as it should have
name and link latter last respectively.

.. note::
  you have the choice to put http:// or not

Qoutes
------
you can edit qoutes in assets/qoute.json.
- qoute first, author name second
- array should be even
