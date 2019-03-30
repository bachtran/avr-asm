# avr-asm

A collection of fiddling I make with avr asm, mostly running on an arduino uno.
So, unless otherwise noted, these projects are for atmega328p.

## Requirements

* [AVRA 1.4+][avra]
* [avrdude][avrdude] to send firmware to MCUs
* [simavr][simavr] for simulations

## Simulations

Unlike my AVR C code, [icemu][icemu] can't be used to simulate programs written
in asm. I started to use [simavr][simavr] which is a very nice library to
emulate AVR.

Each example has a simulation and that simulation can be built with
`make simulation`. Running the simulation generates a VCD file that can then be
opened with [gtkwave][gtkwave] for debugging.

[avra]: http://avra.sourceforge.net/
[avrdude]: https://www.nongnu.org/avrdude/
[icemu]: https://github.com/hsoft/icemu
[simavr]: https://github.com/buserror/simavr
[gtkwave]: http://gtkwave.sourceforge.net/
