#include <stdlib.h>
#include <stdio.h>
#include <libgen.h>
#include <pthread.h>

#include <simavr/avr_ioport.h>
#include <simavr/sim_avr.h>
#include <simavr/sim_elf.h>
#include <simavr/sim_vcd_file.h>

#include "../sim_common.h"

avr_vcd_t vcd_file;

int main(int argc, char *argv[])
{
    avr_t * avr = sim_init("attiny45", 1000000UL, "blink.hex");
    if (avr == NULL) {
        return 1;
    }
	avr_vcd_init(avr, "gtkwave_output.vcd", &vcd_file, 100000 /* usec */);
	avr_vcd_add_signal(&vcd_file,
		avr_io_getirq(avr, AVR_IOCTL_IOPORT_GETIRQ('B'), 0), 1 /* bit */,
		"PORTB0");
	printf( "\nLaunching:\n");

    avr_vcd_start(&vcd_file);
	int state = cpu_Running;
    for (int i=0; i<avr->frequency*5; i++) {
        if ((state == cpu_Done) || (state == cpu_Crashed)) {
            break;
        }
		state = avr_run(avr);
    }
    avr_vcd_stop(&vcd_file);
}

