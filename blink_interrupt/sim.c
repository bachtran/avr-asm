#include <stdlib.h>
#include <stdio.h>
#include <libgen.h>
#include <pthread.h>

#include <simavr/avr_ioport.h>
#include <simavr/sim_avr.h>
#include <simavr/sim_elf.h>
#include <simavr/sim_vcd_file.h>

/* TODO: fix this simulation
 *
 * The simulation runs, but doesn't result in pin changes in the VCD (but pin
 * changes *do* happen on hardware).
 */

avr_t * avr = NULL;
avr_vcd_t vcd_file;

int main(int argc, char *argv[])
{
	elf_firmware_t f;
	const char * fname =  "blink.bin";

	printf("Firmware pathname is %s\n", fname);
	elf_read_firmware(fname, &f);

	/*printf("firmware %s f=%d mmcu=%s\n", fname, (int)f.frequency, f.mmcu);*/

	avr = avr_make_mcu_by_name("atmega328p");
	if (!avr) {
		fprintf(stderr, "%s: AVR '%s' not known\n", argv[0], f.mmcu);
		exit(1);
	}
	avr_init(avr);
	avr_load_firmware(avr, &f);
    avr->frequency = 16000000UL;

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

