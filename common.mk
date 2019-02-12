MCU ?= atmega328p

USBDEV ?= /dev/ttyACM0
BAUDS ?= 115200
AVRDUDEMCU ?= $(MCU)
AVRDUDEARGS ?= -F -V -c arduino -P $(USBDEV) -b $(BAUDS)

# Rules

.PHONY: send clean

all: $(PROGNAME).hex
	@echo Done!

send: $(PROGNAME).hex
	avrdude $(AVRDUDEARGS) -p $(AVRDUDEMCU) -U flash:w:$(PROGNAME).hex

clean:
	rm -f $(PROGNAME).hex $(PROGNAME).bin

$(PROGNAME).bin: $(PROGNAME).S
	avr-gcc -mmcu=$(MCU) -o $@ $< -nostdlib

$(PROGNAME).hex: $(PROGNAME).bin
	avr-objcopy -O ihex -R .eeprom $< $@

