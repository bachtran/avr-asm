# avr-asm

A collection of fiddling I make with avr asm, mostly running on an arduino uno.
So, unless otherwise noted, these projects are for atmega328p.

You will notice that I don't use any external definitions, but hex codes. That's
just me, wanting to experiment on the concept of writing code with nothing but
the datasheet as a reference.

## Simulations

Unlike my AVR C code, [icemu][icemu] can't be used to simulate programs written
in asm. I started to use [simavr][simavr] which is a very nice library to
emulate AVR.

Each example has a simulation and that simulation can be built with
`make simulation`. Running the simulation generates a VCD file that can then be
opened with [gtkwave][gtkwave] for debugging.

[icemu]: https://github.com/hsoft/icemu
[simavr]: https://github.com/buserror/simavr
[gtkwave]: http://gtkwave.sourceforge.net/
