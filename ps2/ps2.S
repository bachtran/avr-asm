.include "m328Pdef.inc"

; Receives keystrokes from PS/2 keyboard and prints their hexadecimal
; representation through the serial link.
;
; PS/2 is a bidirectional protocol, but in this program, we only care about
; receiving keystrokes. We don't send anything to the keyboard.
;
; The PS/2 keyboard has two data wires: Clock and Data. It is the keyboard that
; drives the clock with about 30-50 us between each clock.
;
; We wire the Clock to INT0 (PD2) and make it trigger an interrupt on the
; falling edge (the edge, in the PS/2 protocol, when data is set).
;
; Data is sent by the keyboard in 11-bit frames. 1 start bit (0), 8 data bits,
; one parity bit, one stop bit (1).
;
; Parity bit is set if number of bits in data bits is even. Unset otherwise.
;
; *** Receiving a data frame ***
;
; In idle mode, R18 is zero. When INT0 is triggered, it is increased and R17 is
; loaded with 0x80. We do this because we're going to right shift our data in
; (byte is sent LSB first). When the carry flag is set, we'll know we're
; finished. When that happens, we increase R18 again. We're waiting for parity
; bit. When we get it, we check parity and increase R18 again. We're waiting
; for stop bit. After we receive stop bit, we reset R18 to 0.
;
; On error, we ignore and reset our counters.

; *** Register Usage ***
;
; Flags on GPIOs
; GPIOR0 - bit 0: Set when INT_INT0 has received a new bit
; GPIOR0 - bit 1: The value of the new bit received

; R1: when set, indicates that value in R17 is valid
; R16: tmp stuff
; R17: recv buffer. Whenever we receive a bit, we push it in there.
; R18: recv step:
;      - 0: idle
;      - 1: receiving data
;      - 2: awaiting parity bit
;      - 3: awaiting stop bit
;      it reaches 11, we know we're finished with the frame.
; R19: char to send to UART

; *** Constants ***
;

; 9600 bauds at 16mhz
.equ	BAUD_PRESCALE =	103
.equ	CLK = PIND2
.equ	DATA = PIND3


	rjmp	main
	rjmp	hdlINT0

; Read DATA and set GPIOR0 bits 0 and 1 accordingly
; no SREG fiddling because no SREG-modifying instruction
hdlINT0:
	cbi	GPIOR0, 1	; clear received data
	sbic	PIND, DATA	; DATA clear? skip next
	sbi	GPIOR0, 1	; DATA set? record this
	sbi	GPIOR0, 0	; indicate that we've received a bit
	reti

main:
        ldi     r16, low(RAMEND)
        out     SPL, r16
        ldi     r16, high(RAMEND)
        out     SPH, r16

	; init variables
	clr	r1
	clr	r18

	; Setup UART
	ldi	r16, high(BAUD_PRESCALE)
	sts	UBRR0H, r16
	ldi	r16, low(BAUD_PRESCALE)
	sts	UBRR0L, r16

	ldi	r16, (1<<TXEN0)
	sts	UCSR0B, r16

	; Setup int0
	ldi	r16, (1<<ISC01)	; INT0, falling edge
	sts	EICRA, r16
	ldi	r16, (1<<INT0)
	out	EIMSK, r16

	sei

loop:
	sbic	GPIOR0, 0	; did we receive a bit?
	rjmp	processbit	; yes? process
	tst	r1
	brne	sendAsHex	; r1 is non-zero? char is ready to send
	rjmp	loop

; Send value in R17 to UART in hexadecimal form (two characters).
sendAsHex:
	clr	r1
	mov	r16, r17
	swap	r16
	rcall	fmtHex
	mov	r19, r16
	rcall	sendchar
	mov	r16, r17
	rcall	fmtHex
	mov	r19, r16
	rcall	sendchar
	rjmp	loop

; Process the data bit received in INT0 handler.
processbit:
	cbi	GPIOR0, 0	; clear received bit
	tst	r18
	breq	processbits0
	cpi	r18, 1
	breq	processbits1
	cpi	r18, 2
	breq	processbits2
	; step 3: stop bit
	clr	r18		; happens in all cases
	; DATA has to be set
	sbic	GPIOR0, 1	; skip if DATA is clear.
	inc	r1		; indicate that value in r17 is good
	rjmp	loop
processbits0:
	; step 0 - start bit
	; DATA has to be cleared
	sbic	GPIOR0, 1	; skip if DATA cleared.
	rjmp	loop		; set? error. no need to do anything. keep r18
				; as-is.
	; DATA is cleared. prepare r17 and r18 for step 1
	inc	r18
	ldi	r17, 0x80
	clr	r1
	rjmp	loop

processbits1:
	; step 1 - receive bit
	; We're about to rotate the carry flag into r17. Let's set it first
	; depending on whether DATA is set.
	clc
	sbic	GPIOR0, 1	; skip if DATA cleared.
	sec
	; Carry flag is set
	ror	r17
	; Good. now, are we finished rotating? If carry flag is set, it means
	; that we've rotated in 8 bits.
	brcc	loop		; we haven't finished yet
	; We're finished, go to step 2
	inc	r18
	rjmp	loop
processbits2:
	; step 2 - parity bit
	; TODO: check parity
	inc	r18
	rjmp	loop

; Transforms lower nibble of R16 into a hexadecimal character (0-F).
fmtHex:
	andi	r16, 0xf
	cpi	r16, 9
	brcc	fmtHexAlpha	; r16 > 9 means value is alpha
	subi	r16, -'0'
	ret
fmtHexAlpha:
	subi	r16, -('A'-10)
	ret

; Send character in R19 through UART. Waits until UART is ready before doing so.
sendchar:
	lds	r16, UCSR0A
	sbrs	r16, UDRE0	; UDRE0 is set? skip rjmp and send char.
	rjmp	sendchar
	sts	UDR0, r19
	ret

