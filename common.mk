AVRDUDEMCU ?= atmega328p

USBDEV ?= /dev/ttyACM0
BAUDS ?= 115200
ifeq ($(AVRDUDEMCU),atmega328p)
	AVRDUDEARGS ?= -F -V -c arduino -P $(USBDEV) -b $(BAUDS)
else
	AVRDUDEARGS ?= -c usbtiny -P usb 
endif
TARGET = $(PROGNAME).hex
AVRA = avra

# Rules

.PHONY: send clean

all: $(TARGET)
	@echo Done!

send: $(TARGET)
	avrdude $(AVRDUDEARGS) -p $(AVRDUDEMCU) -U flash:w:$<

clean:
	rm -f $(TARGET) $(PROGNAME).S.eep.hex $(PROGNAME).S.obj simulation

$(TARGET): $(PROGNAME).S
	$(AVRA) $(FLAGS) -o $@ $<

simulation: sim.c ../sim_common.c $(TARGET)
	$(CC) $(LDFLAGS) -lsimavr -lm -lelf $< ../sim_common.c -o $@
	
