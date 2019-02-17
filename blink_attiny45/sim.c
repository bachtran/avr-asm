#include <stdlib.h>
#include <stdio.h>
#include <libgen.h>
#include <pthread.h>

#include <simavr/avr_ioport.h>
#include <simavr/sim_avr.h>
#include <simavr/sim_elf.h>
#include <simavr/sim_vcd_file.h>

avr_t * avr = NULL;
avr_vcd_t vcd_file;

int main(int argc, char *argv[])
{
	elf_firmware_t f;
	const char * fname =  "blink.bin";

	printf("Firmware pathname is %s\n", fname);
	if (elf_read_firmware(fname, &f) == -1) {
        printf("Unable to load firmware\n");
        return 1;
    }
    f.frequency = 1000000UL;

	avr = avr_make_mcu_by_name("attiny45");
	if (!avr) {
		fprintf(stderr, "%s: AVR '%s' not known\n", argv[0], f.mmcu);
		exit(1);
	}
	avr_init(avr);
    avr->log = LOG_DEBUG;
	avr_load_firmware(avr, &f);
    printf("Frequency: %d\n", avr->frequency);

	avr_vcd_init(avr, "gtkwave_output.vcd", &vcd_file, 100000 /* usec */);
	avr_vcd_add_signal(&vcd_file,
		avr_io_getirq(avr, AVR_IOCTL_IOPORT_GETIRQ('B'), 5), 1 /* bit */,
		"PORTB5");
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

