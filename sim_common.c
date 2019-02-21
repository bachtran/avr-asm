#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <simavr/sim_elf.h>
#include <simavr/sim_hex.h>
#include "sim_common.h"

avr_t* sim_init(const char *mcu_name, unsigned long freq, const char *hex_fname)
{
	elf_firmware_t f = {{0}};
    ihex_chunk_p chunk = NULL;
    int cnt = read_ihex_chunks(hex_fname, &chunk);
    if (cnt <= 0) {
		fprintf(stderr, "Unable to load IHEX\n");
        return NULL;
    }
    f.flash = chunk[0].data;
    f.flashsize = chunk[0].size;
    f.flashbase = chunk[0].baseaddr;
    printf("Load HEX flash %08x, %d\n", f.flashbase, f.flashsize);
    for (int ci = 1; ci < cnt; ci++) {
        int diff = chunk[ci].baseaddr - f.flashbase;
        int newsize = diff + chunk[ci].size;
        f.flash = realloc(f.flash, newsize);
        memset(f.flash + f.flashsize, 0, newsize - f.flashsize);
        memcpy(f.flash + diff, chunk[ci].data, chunk[ci].size);
        f.flashsize = newsize;
        printf("Merge HEX flash %08x, %d\n", chunk[ci].baseaddr, chunk[ci].size);
    }


	avr_t *mcu = avr_make_mcu_by_name(mcu_name);
	if (!mcu) {
		fprintf(stderr, "AVR '%s' not known\n", mcu_name);
        return NULL;
	}
    f.frequency = freq;
	avr_init(mcu);
	avr_load_firmware(mcu, &f);
    return mcu;
}
