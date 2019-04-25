.include "m328Pdef.inc"

; Set the MCU in SPI slave mode and wait for input. Every time it receives an
; input, it spits it in the UART (raw, so some characters will mess up
; terminals).
;
; This goes hand in hand with the "driver" program with uses libftdi to make
; a FTDI device connected through USB to act as a SPI master and send bytes to
; its slave.

; REGISTER USAGE
;
; R16: tmp stuff
; R17: char to send in SENDCHAR. We read SPI directly in this register.

; CONSTANTS
;

; 9600 bauds at 16mhz
.equ	BAUD_PRESCALE =	103

; CODE
;

	rjmp    main

main:
        ldi     R16, low(RAMEND)
        out     SPL, R16
        ldi     R16, high(RAMEND)
        out     SPH, R16

	clr	R18

	ldi	R16, high(BAUD_PRESCALE)
	sts	UBRR0H, R16
	ldi	R16, low(BAUD_PRESCALE)
	sts	UBRR0L, R16

	ldi	R16, (1<<TXEN0)
	sts	UCSR0B, R16

	; setup spi (slave)
	sbi	DDRB, DDB4	; MISO output
	ldi	r16, (1<<SPE) | (1<<CPOL) ; enable SPI
	out	SPCR, r16

loop:
	in	r16, SPSR
	sbrs	r16, SPIF	; SPIF is set? We have data
	rjmp	loop		; otherwise, wait...
	in	r17, SPDR
	rcall	sendchar
	rjmp    loop

; Sends char in R17 to TX
sendchar:
	lds	R16, UCSR0A
	sbrs	R16, UDRE0	; UDRE0 is set? skip rjmp and send char.
	rjmp	sendchar
	sts	UDR0, R17
	ret
