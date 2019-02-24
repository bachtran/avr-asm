; The goal of this example is to debug what I think is a broken timer1 in
; simavr...
; REGISTER USAGE
;
; R1:  Whether the LED is on
; R16: tmp stuff

.include "tn45def.inc"

	RJMP    MAIN

MAIN:
	LDI	R16, low(RAMEND)
        OUT	SPL, R16
        LDI	R16, high(RAMEND)
	OUT	SPH, R16

        SBI     DDRB, DDB0
        CBI     PORTB, PORTB0

	; We want an approximate 1s delay. A prescaler of 1/4096 * 256 ticks
	; to overflow at 1MHz fits the bill.
        IN      R16, TCCR1
        ORI     R16, 0b1101	; 4096 prescaler
        OUT     TCCR1, R16

	CLR	R1

LOOP:
	IN	R16, TIFR
	SBRC	R16, TOV1	; is TOV flag clear?
	RCALL	TOGGLE
        RJMP    LOOP

TOGGLE:
	LDI	R16, 1 << TOV1
	OUT	TIFR, R16
	INC	R1
        CBI     PORTB, PORTB0
        SBRS    R1, 0		; if LED is on
        SBI     PORTB, PORTB0
	RET
