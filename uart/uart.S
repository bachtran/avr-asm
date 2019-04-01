.include "m328Pdef.inc"

; Send "ping", waits for a character, the echo back "pongX" where X is the
; character that was read.

; REGISTER USAGE
;
; R16: tmp stuff
; R17: char to send in SENDCHAR
; R18: the char that has just been read
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

	CLR	R18

	LDI	R16, high(BAUD_PRESCALE)
	STS	UBRR0H, R16
	LDI	R16, low(BAUD_PRESCALE)
	STS	UBRR0L, R16

	LDI	R16, (1<<TXEN0) | (1<<RXEN0)
	STS	UCSR0B, R16


LOOP:
	RCALL	PING
	RCALL	READCHAR
	RCALL	PONG
	RJMP    LOOP

; Send "ping" to TX, followed by a newline
PING:
	LDI	ZH, high(DB_PING<<1)
	LDI	ZL, low(DB_PING<<1)
	RCALL	SENDSTR
	LDI	ZH, high(DB_LINEFEED<<1)
	LDI	ZL, low(DB_LINEFEED<<1)
	RCALL	SENDSTR
	RET

; Waits until a char is read, then put it in R18
READCHAR:
	LDS	R16, UCSR0A
	SBRS	R16, RXC0	; RXC0 is set? skip rjmp and fetch char.
	RJMP	READCHAR
	LDS	R18, UDR0
	RET

; Send "pong" to TX, followed by the char in R18, followed by a newline
PONG:
	LDI	ZH, high(DB_PONG<<1)
	LDI	ZL, low(DB_PONG<<1)
	RCALL	SENDSTR
	MOV	R17, R18
	RCALL	SENDCHAR
	LDI	ZH, high(DB_LINEFEED<<1)
	LDI	ZL, low(DB_LINEFEED<<1)
	RCALL	SENDSTR
	RET

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

DB_LINEFEED:	.DB 0x0a, 0x0d, 0
DB_PING:	.DB "ping", 0
DB_PONG:	.DB "pong", 0
