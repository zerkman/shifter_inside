# Shifter Inside - remove top and bottom borders in GEM desktop

Copyright (c) 2023-2024 by François Galea (fgalea à free.fr)

This is a program for the Atari ST/STe which uses classical demoscene-style
top and bottom border removal techniques to extend the screen size of
the standard graphical interface, GEM.

It typically enables screen sizes of 640×276 in medium resolution, or
320×276 in low resolution. No screen size improvement is available for high
resolution monochrome mode.

## Binary build

This program was developed using [vasm](http://sun.hasenbraten.de/vasm/).
If the `vasmm68k_mot` binary is in your execution path, you should be able
to build `SHIN.PRG` by just typing the command `make`.

It also should be no problem to build it using Devpac on the Atari machine.

## Installation

Build and copy `SHIN.PRG` into the `AUTO` folder of your system disk.

## Caveats

This program does what is technically possible to use border removal on
the system shell. However, such techniques usually require to work on no
interrupt environments, which is not possible when running the user OS.
Even though countermeasures can be used to avoid being disturbed by the
system clock or keyboard interrupts, there is no known way to counteract
disturbances from DMA transfers (Floppy, Blitter, ACSI devices) which
basically stop the CPU during transfers.


Shifter Inside is distributed under the GNU General Public License v3 licence.
See the LICENSE file or https://www.gnu.org/licenses/gpl-3.0.html for more details.

