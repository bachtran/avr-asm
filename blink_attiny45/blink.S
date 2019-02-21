.device ATtiny45

; I just want to make sure that simavr works well with attiny MCUs...
; REGISTER USAGE
;
; R1: overflow counter
; R16: tmp stuff

	RJMP    MAIN

MAIN:
	CLR	R16
	OUT	0x3f, R16	; SREG
        LDI     R16, 0x5f	; low RAMEND
        OUT     0x3d, R16	; SPL
        LDI     R16, 0x01	; high RAMEND
        OUT     0x3e, R16	; SPH

        SBI     0x17, 5		; DDRB5, output
        CBI     0x18, 5		; PORTB5, off

	; To have a blinking delay that's visible, we have to prescale a lot.
	; The maximum prescaler is 1024, which makes our TCNT0 increase
	; 976 times per second, which means that it overflows 4 times per
	; second.
        IN      R16, 0x33	; TCCR0B
        ORI     R16, 0x05	; CS00 + CS02 = 1024 prescaler
        OUT     0x33, R16

	CLR	R1

LOOP:
	IN	R16, 0x38	; TIFR0
	SBRC	R16, 1		; is TOV flag clear?
	RCALL	TOGGLE
        RJMP    LOOP

TOGGLE:
	LDI	R16, 0x01
	OUT	0x38, R16	; TIFR0
	INC	R1
        CBI     0x18, 5		; PORTB5, off
        SBRS    R1, 1		; if LED is on
        SBI     0x18, 5		; PORTB5, on
	RET
