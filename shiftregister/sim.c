#include <stdlib.h>
#include <stdio.h>
#include <libgen.h>
#include <pthread.h>

#include <simavr/avr_ioport.h>
#include <simavr/sim_avr.h>
#include <simavr/sim_vcd_file.h>

#include "../sim_common.h"

avr_vcd_t vcd_file;

int main(int argc, char *argv[])
{
    avr_t * avr = sim_init("atmega328p", 16000000UL, "shiftregister.hex");
    if (avr == NULL) {
        return 1;
    }
	avr_vcd_init(avr, "gtkwave_output.vcd", &vcd_file, 100000 /* usec */);
	avr_vcd_add_signal(&vcd_file,
		avr_io_getirq(avr, AVR_IOCTL_IOPORT_GETIRQ('D'), 2), 1 /* bit */,
		"PORTD2");
	avr_vcd_add_signal(&vcd_file,
		avr_io_getirq(avr, AVR_IOCTL_IOPORT_GETIRQ('D'), 3), 1 /* bit */,
		"PORTD3");
	printf( "\nLaunching:\n");

    avr_vcd_start(&vcd_file);
	int state = cpu_Running;
    for (int i=0; i<avr->frequency; i++) {
        if ((state == cpu_Done) || (state == cpu_Crashed)) {
            break;
        }
		state = avr_run(avr);
    }
    avr_vcd_stop(&vcd_file);
}

