.include "m328Pdef.inc"

; Repeatedly sends "Hello World!" through the UART.

; REGISTER USAGE
;
; R16: tmp stuff
; R17: char to send in SENDCHAR
; Z: String to send *in program memory*

; CONSTANTS
;

; 9600 bauds at 16mhz
.equ	BAUD_PRESCALE =	103

; CODE
;

	RJMP    MAIN

MAIN:
        LDI     R16, low(RAMEND)
        OUT     SPL, R16
        LDI     R16, high(RAMEND)
        OUT     SPH, R16

	LDI	R16, high(BAUD_PRESCALE)
	STS	UBRR0H, R16
	LDI	R16, low(BAUD_PRESCALE)
	STS	UBRR0L, R16

	LDI	R16, 1<<TXEN0
	STS	UCSR0B, R16

LOOP:
	LDI	ZH, high(HELLO<<1)
	LDI	ZL, low(HELLO<<1)
	RCALL	SENDSTR
        RJMP    LOOP

; Sends char in R17 to TX
SENDCHAR:
	LDS	R16, UCSR0A
	SBRS	R16, UDRE0	; UDRE0 is set? skip rjmp and send char.
	RJMP	SENDCHAR
	STS	UDR0, R17
	RET

; Sends string pointed to by Z, in the program's memory, to TX until a value
; 0 is encountered.
SENDSTR:
	LPM	R17, Z+
	TST	R17
	BREQ	SENDSTR_END	; R17 is zero? stop
	RCALL	SENDCHAR
	RJMP	SENDSTR
SENDSTR_END:
	RET

HELLO: .DB "Hello World!", 0x0a, 0x0d, 0x00
