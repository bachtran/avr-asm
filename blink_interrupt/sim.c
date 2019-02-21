#include <stdlib.h>
#include <stdio.h>
#include <libgen.h>
#include <pthread.h>

#include <simavr/avr_ioport.h>
#include <simavr/sim_avr.h>
#include <simavr/sim_vcd_file.h>

#include "../sim_common.h"

/* TODO: fix this simulation
 *
 * The simulation runs, but doesn't result in pin changes in the VCD (but pin
 * changes *do* happen on hardware).
 */

avr_vcd_t vcd_file;

int main(int argc, char *argv[])
{
    avr_t * avr = sim_init("atmega328p", 16000000UL, "blink.S.hex");
    if (avr == NULL) {
        return 1;
    }
	avr_vcd_init(avr, "gtkwave_output.vcd", &vcd_file, 100000 /* usec */);
	avr_vcd_add_signal(&vcd_file,
		avr_io_getirq(avr, AVR_IOCTL_IOPORT_GETIRQ('B'), 5), 1 /* bit */,
		"PORTB5");
	printf( "\nLaunching:\n");

    avr_vcd_start(&vcd_file);
	int state = cpu_Running;
    // unlike the "blink" example, our MCU sleeps here, so running frequency*5
    // time to get approximately 5 seconds is waaay too much. We have to guess
    // a figure here.
    for (int i=0; i<5000; i++) {
        if ((state == cpu_Done) || (state == cpu_Crashed)) {
            break;
        }
		state = avr_run(avr);
    }
    avr_vcd_stop(&vcd_file);
}

