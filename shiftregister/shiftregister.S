; SHIFT REGISTER CONTROLLER
;
; This program drives a CD74AC164 to display digits on a 7-segment display.
; The SR is really fast on input. At minimal voltage, it has a minimum clock of
; 73ns and at nominal voltage, 8ns. At 16MHz, there are 62ns between each of our
; ticks, so we can hardly go too fast. For good measure though, we add a NOP in
; between our CP toggling, just to be sure. But it should be more than enough.
; (actually, after some real world tests, 2 NOPs were needed)
;
; REGISTER USAGE
;
; R16: tmp stuff
; R17: digit selector
; R18: indicator that a OVF event happened
; R19: SREG storage for interrupt
; R20: data being sent to the SR
; R21: data send counter. set to 8 before calling SENDSR

; PIN USAGE
;
; PORTD2: CP
; PORTD3: DS

.org 0x0000
	RJMP    MAIN

.org 0x0034	; TIMER1_OVF
	RJMP	OVF

MAIN:
        LDI     R16, 0xff	; low RAMEND
        OUT     0x3d, R16	; SPL
        LDI     R16, 0x08	; high RAMEND
        OUT     0x3e, R16	; SPH

        SBI     0x0a, 2		; DDRD2, output
        SBI     0x0a, 3		; DDRD3, output

	; set timer1 prescaler to 1024
	LDS	R16, 0x81	; TCCR1B
	ORI	R16, 0x05	; CS00 + CS02 = 1024 prescaler
	STS	0x81, R16

	; Enable TIMER1_OVF
	LDS	R16, 0x6f	; TIMSK1
	ORI	R16, 0x01	; TOIE1
	STS	0x6f, R16

	CLR	R17		; select digit 0
	SER	R18		; we initially set it to have a first refresh

	SEI

LOOP:
	; stay in empty loop unless we had an OVF event
	SBRS	R18, 0
	RJMP	LOOP
	CLR	R18

	; initialize timer1 counter to have approximately 1s. at a prescaler
	; of 1024, we have 15625 ticks per second. Setting the high counter
	; register to 0xc3 does the trick.
	; fun note: just setting TCNT1H and not caring about lower resolution
	;           (TCNT1L) doesn't work and sets nothing. Both registers have
	;	    to be set.
	LDI	R16, 0xc3
	STS	0x85, R16	; TCNT1H
	STS	0x84, R16	; TCNT1L

	; send selected digit
	RCALL	LDDIGIT
	LDI	R21, 0x08
	RCALL	SENDSR		; send data to SR

	SLEEP

	; update digit
	INC	R17
	CPI	R17, 10
	BRNE	.+2		; if == 10, clear to 0
	CLR	R17

	RJMP    LOOP

; handle TIMER1_OVF
OVF:
	IN	R19, 0x3f	; SREG
	SER	R18
	OUT	0x3f, R19	; SREG
	RETI

; Load the digit selected in R17 into R20
LDDIGIT:
	; load DIGITS' address into Z
	LDI	R31, hi8(DIGITS)
	LDI	R30, lo8(DIGITS)
	CLR	R16		; we need a R with 0 in it for ADC below
	ADD	R30, R17	; Add selected digit offset
	ADC	R31, R16	; in case we carried earlier
	LPM	R20, Z		; deref Z pointer into R20
	RET

; send R20 to shift register.
; set R21 to 8 before calling
SENDSR:
	CBI	0x0b, 3		; PORTD3, low (DS)
	SBRC	R20, 0		; if latest bit isn't cleared, set DS high
	SBI	0x0b, 3		; PORTD3, high (DS)
	RCALL	TOGCP
	LSR	R20		; shift our data right
	DEC	R21
	BRNE	SENDSR		; not zero yet? loop!
	RET

; toggle CP, waiting 1us between pin changes
TOGCP:
	CBI	0x0b, 2		; PORTD2, low (CP)
	NOP			; 62ns between our pin changes
	NOP			; ... and another one
	SBI	0x0b, 2		; PORTD2, high (CP)
	RET

; segment masks for digits from 0 to 9
DIGITS: .byte \
	0b00000010, \
	0b01001111, \
	0b00010001, \
	0b00000101, \
	0b01001100, \
	0b00100100, \
	0b00100000, \
	0b00001111, \
	0b00000000, \
	0b00000100

