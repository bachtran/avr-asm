MCU ?= atmega328p

USBDEV ?= /dev/ttyACM0
BAUDS ?= 115200
AVRDUDEMCU ?= $(MCU)
ifeq ($(AVRDUDEMCU),t45)
	AVRDUDEARGS ?= -c usbtiny -P usb 
else
	AVRDUDEARGS ?= -F -V -c arduino -P $(USBDEV) -b $(BAUDS)
endif
TARGET = $(PROGNAME).hex

# Rules

.PHONY: send clean

all: $(TARGET)
	@echo Done!

send: $(TARGET)
	avrdude $(AVRDUDEARGS) -p $(AVRDUDEMCU) -U flash:w:$<

clean:
	rm -f $(TARGET) $(PROGNAME).S.eep.hex $(PROGNAME).S.obj simulation

$(TARGET): $(PROGNAME).S
	avra $(FLAGS) -o $@ $<

simulation: sim.c ../sim_common.c $(TARGET)
	$(CC) $(LDFLAGS) -lsimavr -lm -lelf $< ../sim_common.c -o $@
	
