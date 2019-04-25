#include <ftdi.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>

// from https://gist.github.com/bjornvaktaren/d2461738ec44e3ad8b3bae4ce69445b4

enum bus_t {
      SK = 0x01, // ADBUS0, SPI data clock
      DO = 0x02, // ADBUS1, SPI data out
      DI = 0x04, // ADBUS2, SPI data in
      CS = 0x08, // ADBUS3, SPI chip select
      L0 = 0x10, // ADBUS4, general-ourpose i/o, GPIOL0
      L1 = 0x20, // ADBUS5, general-ourpose i/o, GPIOL1
      L2 = 0x40, // ADBUS6, general-ourpose i/o, GPIOL2
      L3 = 0x80  // ADBUS7, general-ourpose i/o, GPIOL3
};

int main()
{
    struct ftdi_context ftdi;
    int res = ftdi_init(&ftdi);
    if (res) {
        printf("Init failed\n");
        return res;
    }
    res = ftdi_usb_open(&ftdi, 0x0403, 0x6014);
    if (res) {
        printf("Open failed\n");
        return res;
    }
    ftdi_usb_reset(&ftdi);
    ftdi_set_interface(&ftdi, INTERFACE_ANY);
    ftdi_set_bitmode(&ftdi, 0, 0); // reset
    ftdi_set_bitmode(&ftdi, 0, BITMODE_MPSSE);
    ftdi_usb_purge_buffers(&ftdi);
    usleep(50000); // sleep 50 ms for setup to complete

    // Setup MPSSE; Operation code followed by 0 or more arguments.
    unsigned int icmd = 0;
    unsigned char buf[20] = {0};

    /* Note on polarity and phase
     *
     * I had to mess up a lot with polarity and phase and FTDI's documentation
     * isn't among the most pleasant. After having looked at the output with a
     * logic analyzer, the FT232H does its setup on rising edge, which means
     * that we should read our data on the falling edge on the slave end.
     *
     * Phase-wise, we're on phase 0, which means that we sample on the leading
     * edge. This means that when CS is activated (pulled low), SK should be
     * HIGH so that FTDI's first low pull correctly registers (it seems to
     * expect this if we look at the way MOSI moves).
     *
     * This is why SK is kept high at all times in SET_BITS_LOW operations.
     */
    buf[icmd++] = TCK_DIVISOR; // opcode: set clk divisor
    buf[icmd++] = 0x05; // argument: low bit. 60 MHz / (5+1) = 1 MHz
    buf[icmd++] = 0x00; // argument: high bit.
    buf[icmd++] = DIS_ADAPTIVE; // opcode: disable adaptive clocking
    buf[icmd++] = DIS_3_PHASE; // opcode: disable 3-phase clocking
    buf[icmd++] = SET_BITS_LOW; // opcode: set low bits (ADBUS[0-7])
    buf[icmd++] = SK | CS; // argument: inital pin states
    buf[icmd++] = SK | DO | CS; // argument: pin direction
    if ( ftdi_write_data(&ftdi, buf, icmd) != icmd ) {
        printf("Write failed\n");
        return 1;
    }

    while (1) {
        printf("Enter char:\n");
        int c = getchar();
        printf("%d\n", c);
        if (c < 0x20) {
            break;
        }
        getchar(); // eat newline
        // zero the buffer for good measure
        memset(buf, 0, sizeof(buf));
        icmd = 0;

        // Now we will write and read 1 byte.
        // The DO and DI pins should be physically connected on the breadboard.
        // commands to write and read one byte in SPI0 (polarity = phase = 0) mode
        buf[icmd++] = SET_BITS_LOW; // opcode: set low bits (ADBUS[0-7])
        buf[icmd++] = SK; // argument: inital pin states
        buf[icmd++] = SK | DO | CS; // argument: pin direction
        buf[icmd++] = MPSSE_DO_WRITE;
        buf[icmd++] = 0x00; // length low byte, 0x0000 ==> 1 byte
        buf[icmd++] = 0x00; // length high byte
        buf[icmd++] = c; // byte to send
        buf[icmd++] = SET_BITS_LOW; // opcode: set low bits (ADBUS[0-7])
        buf[icmd++] = SK | CS; // argument: inital pin states
        buf[icmd++] = SK | DO | CS; // argument: pin direction

        ftdi_usb_purge_tx_buffer(&ftdi);
        if ( ftdi_write_data(&ftdi, buf, icmd) != icmd ) {
            printf("Write failed\n");
            return 1;
        }
    }
    printf("Done\n");
    ftdi_usb_reset(&ftdi);
    ftdi_usb_close(&ftdi);

    return 0;
}
