;
; Briefing_Timers_Period.asm
;
; Created: XX/03/2019 12:33:00 PM
; Author : TakuMapani
;
.DSEG
	.org 0x0500

  counter: .byte 1


; Demonstration of the Timer Usage and Periodic interrupt capabilities of the ATmega328
; Generate an interrupt 3 seconds from now

; Replace with your application code
.CSEG
	.org	0x0000		; start at beginning of program address
	jmp RESET ; Reset	; reset and interrupt vectors
	jmp INT0_IR ; IRQ0
	jmp INT1_IR ; IRQ1
	jmp PCINT0_IR ; PCINT0
	jmp PCINT1_IR ; PCINT1
	jmp PCINT2_IR ; PCINT2
	jmp WDT_IR ; Watchdog Timeout
	jmp TIM2_COMPA ; Timer2 CompareA
	jmp TIM2_COMPB ; Timer2 CompareB
	jmp TIM2_OVF ; Timer2 Overflow
	jmp TIM1_CAPT ; Timer1 Capture
	jmp TIM1_COMPA ; Timer1 CompareA
	jmp TIM1_COMPB ; Timer1 CompareB
	jmp TIM1_OVF ; Timer1 Overflow
	jmp TIM0_COMPA ; Timer0 CompareA
	jmp TIM0_COMPB ; Timer0 CompareB
	jmp TIM0_OVF ; Timer0 Overflow
	jmp SPI_STC ; SPI Transfer Complete
	jmp USART_RXC ; USART RX Complete
	jmp USART_UDRE ; USART UDR Empty
	jmp USART_TXC ; USART TX Complete
	jmp ADC_CC ; ADC Conversion Complete
	jmp EE_RDY ; EEPROM Ready
	jmp ANA_COMP ; Analog Comparator
	jmp TWI_IR ; 2-wire Serial
	jmp SPM_RDY ; SPM Ready
;
; non configured interrupts - do nothing
;
;INT0_IR: rjmp  noint		; we use interrupt 0
INT1_IR: rjmp  noint
PCINT0_IR: rjmp  noint
PCINT1_IR: rjmp  noint
PCINT2_IR: rjmp  noint
WDT_IR: rjmp  noint
TIM2_COMPA: rjmp  noint
TIM2_COMPB: rjmp  noint
TIM2_OVF: rjmp  noint
TIM1_CAPT: rjmp  noint
;TIM1_COMPA: rjmp  noint
TIM1_COMPB: rjmp  noint	; we use Timer 1, comparitor B
TIM1_OVF: rjmp  noint
TIM0_COMPA: rjmp  noint
TIM0_COMPB: rjmp  noint
TIM0_OVF: rjmp  noint
SPI_STC: rjmp  noint
USART_RXC: rjmp  noint
USART_UDRE: rjmp  noint
USART_TXC: rjmp  noint
ADC_CC: rjmp  noint
EE_RDY: rjmp  noint
ANA_COMP: rjmp  noint
TWI_IR: rjmp  noint
SPM_RDY: rjmp  noint
;
; Generic catch everything routine.
; We could jump back to reset to restart everything again, which would be safer.
;
error:
noint:	inc	r16
	rjmp	noint
;
; Main program start. Configure the system and execute the main loop
;
;#define secondTC 45
;#define secCount 46
RESET:	ldi	r16,high(RAMEND) ; Set Stack Pointer to top of RAM
	out	SPH,r16
	ldi	r16,low(RAMEND)
	out	SPL,r16


;*******************************************************************************
;LED out
cbi DDRD,4
sbi DDRB,2
sbi PORTD,4
ldi r16,0x00
sts counter,r16

;*****************************************************************************

	call	t1_int_in_3Sec	; configure for an interrupt in 3 seconds
	sei			; enable interrupts globally

;*************************************MAIN**************************************
; The main loop is just a sleep instruction
;
main_loop:
;call poll_button
	rjmp	main_loop

poll_button:
	push r16
	push r17
	lds r17,counter
	ldi r16,0xff
	polling:
		sbic PIND,4
		rjmp return_polling
		dec r16
		brne polling
		inc r17
		cpi r17,10
		breq LED_on_off
		rjmp return_polling

	LED_on_off:
		clr r17
		sbic PORTB,2
		rjmp turn_off
		sbi PORTB,2
		rjmp return_polling
	turn_off:
		cbi PORTB,2

	return_polling:
		sts counter,r17
		pop r17
		pop r16
		ret


; Enable an interrupt in 3 seconds using timer 1.
;
; The counter will be running at 16,000,000 HZ / 1024
; = 15625 ticks per second
;
; we wish to delay for 3 seconds:
; = 15625 * 3
; = 46875 count after 3 seconds
; To calculate the tone frequency
; num = 1,000,000 / frequency
; for 'A' (440Hz)
;	1000000/440 = 2273
;
t1_int_in_3Sec:
	push	r16
	push	r17
	push	r18
	lds	r18,TIMSK1	; save current value
	clr	r16		; disables all interrupts from Timer 1
	sts	TIMSK1,r16
	sts	TCCR1B,r16	; temporarily stop the clock
	ldi	r16,0b00000000	; port A normal, port B normal, WGM=0000 (Normal)
	sts	TCCR1A,r16
	ldi	r17,HIGH(1625)	; set counter to 46875
	ldi	r16,LOW(1625)
	sts	OCR1AH,r17
	sts	OCR1AL,r16
	clr	r16		; clear current count
	sts	TCNT1H,r16
	sts	TCNT1L,r16
	ldi	r16,0b00001101	; noise = 0, WGM=0000, clk = /1024
	sts	TCCR1B,r16
	ldi	r16,0b00000000
	sts	TCCR1C,r16
	ori	r18,0b00000010	; interrupt enabled when OCB match (and other interrupts)
	sts	TIMSK1,r18
	pop	r18
	pop	r17
	pop	r16
	ret
;
; Clear any pending interrupts from timer 1.
;
t1_clear:
	push	r16
	clr	r16		; disables all interrupts from Timer 1
	sts	TIMSK1,r16
	sts	TCCR1B,r16	; temporarily stop the clock
	pop	r16
	ret
;
; Interrupt handling routines.
;

;
; interrupt INT0 - turn off timer 1
;
INT0_IR:
	call	t1_clear
	cbi	PORTB,3
	reti

;poll_button
/*poll_button:
	push r16
	push r17
	lds r17,counter
	ldi r16,0xff
	polling:
		sbis PORTD,4
		rjmp return_polling
		dec r16
		brne polling
		inc r17
		cpi r17,10
		breq LED_on_off
		rjmp return_polling

	LED_on_off:
		clr r17
		sbis PORTB,2
		rjmp turn_off
		sbi PORTB,2
		rjmp return_polling
	turn_off:
		cbi PORTB,2

	return_polling:
		sts counter,r17
		pop r17
		pop r16
		ret*/






;
; interrupt timer 1 match compare B
;
TIM1_COMPA:
	call poll_button
	reti

;*******************************************************************************
