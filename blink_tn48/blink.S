; I just want to make sure that simavr works well with attiny MCUs...
; REGISTER USAGE
;
; R1: overflow counter
; R16: tmp stuff

.include "tn48def.inc"

	RJMP    MAIN

MAIN:
	LDI	R16, low(RAMEND)
        OUT	SPL, R16
        LDI	R16, high(RAMEND)
	OUT	SPH, R16

        SBI     DDRB, DDB5
        CBI     PORTB, PORTB5

	; To have a blinking delay that's visible, we have to prescale a lot.
	; The maximum prescaler is 1024, which makes our TCNT0 increase
	; 976 times per second, which means that it overflows 4 times per
	; second.
        IN      R16, TCCR0A
        ORI     R16, 0x05	; CS00 + CS02 = 1024 prescaler
        OUT     TCCR0A, R16

	CLR	R1

LOOP:
	IN	R16, TIFR0	; TIFR0
	SBRC	R16, TOV0	; is TOV flag clear?
	RCALL	TOGGLE
        RJMP    LOOP

TOGGLE:
	LDI	R16, 1 << TOV0
	OUT	TIFR0, R16
	INC	R1
        CBI     PORTB, PORTB5
        SBRS    R1, 1		; if LED is on
        SBI     PORTB, PORTB5
	RET
