MCU ?= atmega328p

USBDEV ?= /dev/ttyACM0
BAUDS ?= 115200
AVRDUDEMCU ?= $(MCU)
AVRDUDEARGS ?= -F -V -c arduino -P $(USBDEV) -b $(BAUDS)
TARGET = $(PROGNAME).S.hex

# Rules

.PHONY: send clean

all: $(TARGET)
	@echo Done!

send: $(TARGET)
	avrdude $(AVRDUDEARGS) -p $(AVRDUDEMCU) -U flash:w:$<

clean:
	rm -f $(TARGET) $(PROGNAME).S.eep.hex $(PROGNAME).S.cof $(PROGNAME).S.obj simulation

$(TARGET): $(PROGNAME).S
	avra $<

simulation: sim.c ../sim_common.c $(TARGET)
	$(CC) $(LDFLAGS) -lsimavr -lm -lelf $< ../sim_common.c -o $@
	
