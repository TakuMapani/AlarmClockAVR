;
; Briefing_Timers_Period.asm
;
; Created: 4/04/2018 12:33:00 PM
; Author : mq20162718
;
.DSEG
	.org 0x0500
	secCount: .byte 1
	secCountDis: .byte 1
	setDis: .byte 2
	month: .byte 1

;display values needed
  setAM_PM: .byte 2 ; 0x41 0x4d(AM) or 0x50 0x4D (PM)
  setSpace: .byte 1 ;0x20
  hTenth: .byte 1
  hUnit: .byte 1
  setHSemi: .byte 1 ;0x3a
  mTenth: .byte 1
  mUnit: .byte 1
  setMSemi: .byte 1 ;0x3a
  sTenth: .byte 1
  sUnit: .byte 1

  newLine: .byte 1

  AlarmOn: .byte 2
  spaceAlarm: .byte 1

  dayTenth: .byte 1
  dayUnit: .byte 1
  slashYear: .byte 1

  monthTenth: .byte 1
  monthUnt: .byte 1
  slashMonth: .byte 1

  yearTenth: .byte 1
  yearUnit: .byte 1


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

;******************************************************************************
;LCD Display setup
	cbi DDRC,4
	cbi DDRC,5
	sbi PORTC,4
	sbi PORTC,5

;						  Setup TWI interface
	ldi		r16,193		; setup TWI frequency scaling
	sts		TWBR,r16
	ldi		r16,0x00
	sts		TWSR,r16

	ldi		r24,0x27
	call	LCD_Setup
	call	LCD_Clear
;******************************************************************************
;USART (Serial) setup

	sbi	PORTD,1		; set TxD to an RS232 idle value
	sbi	DDRD,1		; and make it output
	clr	r16
	sts	UCSR0A,r16
	ldi	r16,0x18	; enable receiver and transmitter
	sts	UCSR0B,r16
	ldi	r16,0x06	; async, no parity, 1 stop, 8 bits
	sts	UCSR0C,r16
	clr	r16
	sts	UBRR0H,r16
	ldi	r16,0x67	; baud rate divisor 103 (16M/9600 - 1)
	sts	UBRR0L,r16
	clr	r16
;*******************************************************************************
;LED out

	ldi r16,0b00111111
	out	DDRB,r16		; set port B bit 1 to output and low
	clr r16
	out	PORTB,r16
;*****************************************************************************
;DSEG initilization
	;ldi r20,0b00000011;teminal count
	clr r16
	sts secCount,r16

  ldi r16,0x40
  sts newLine,r16

  ldi yl,low(setAM_PM)
  ldi yh,HiGH(setAM_PM)
  ldi r16,0x41
  st y+,r16
  ldi r16,0x4D
  st y+,r16

  ldi YL,LOW(AlarmOn)
  ldi YH,HIGH(AlarmOn)
  ldi r16,0x41
  st Y+,r16
  ldi r16,0x6c
  st Y+,r16

  ldi r16,0x20
  sts setSpace,r16
  sts spaceAlarm,r16

  ldi r16,0x30
  sts mTenth,r16
  sts mUnit,r16

  ldi r16,0x3A
  sts setHSemi,r16
  sts setMSemi,r16

  ldi r16,0x20
  sts hTenth,r16
  ldi r16,0x31
  sts hUnit,r16



  ldi r16,0x30
  sts sTenth,r16
  sts sUnit,r16

	ldi r16,0x30
	sts secCountDis,r16

  ldi r16,0x2F
  sts slashYear, r16
  sts slashMonth,r16

  ldi r16,0x32
  sts dayTenth,r16

  ldi r16,0x39
  sts dayUnit,r16

  ldi r16,0x30
  sts monthTenth,r16

  ldi r16,0x34
  sts monthUnt,r16

  ldi r16,0x31
  sts yearTenth,r16

  ldi r16,0x39
  sts yearUnit,r16


	;setup display data variables
	ldi yl,low(setdis)
	ldi yh,high(setdis)
	ldi r16,0x0c ;
	st y+,r16
	ldi r16,0x01 ;clear display
	st y+,r16

	call	t1_int_in_3Sec	; configure for an interrupt in 3 seconds
	sei			; enable interrupts globally

;*************************************MAIN**************************************
; The main loop is just a sleep instruction
;
main_loop:
	cpi r20,2
	breq updating
	rjmp	main_loop

  updating:
  call update_minuteF

	display_update:
	ldi		r24,0x27
	call	LCD_Setup
	call	LCD_Clear
	ldi		ZL,LOW(setAM_PM)
	ldi		ZH,HIGH(setAM_PM)
	ldi		r25,11
	call	LCD_Text
  lds   r25,newLine
  call  LCD_Position

  ldi		ZL,LOW(AlarmOn)
	ldi		ZH,HIGH(AlarmOn)
	ldi		r25,11
  call LCD_Text

	clr		r20
	rjmp	main_loop	; after interrupt do it again

  update_time:
  push r16
  push r17
  lds r16,sUnit
  lds r17,sTenth

  cpi r16,0x39
  breq update_sTenth
  inc r16
  rjmp return_s

  update_sTenth:
  ldi r16,0x30
  cpi r17,0x35
  breq update_minute
  inc r17
  rjmp return_s

  update_minute:
  call update_minuteF
  ldi r17,0x30

  return_s:
  sts sUnit,r16
  sts sTenth, r17

  pop r17
  pop r16
  ret
;***************************update_minute***************************************
  update_minuteF:
  push r16
  push r17
  lds r16,mUnit
  lds r17,mTenth

  cpi r16,0x39
  breq update_mTenth
  inc r16
  rjmp return_m

  update_mTenth:
  ldi r16,0x30
  cpi r17,0x35
  breq update_hour
  inc r17
  rjmp return_m

  update_hour:
  call update_hourF
  ldi r17,0x30

  return_m:
  sts mUnit,r16
  sts mTenth, r17

  pop r17
  pop r16
  ret

;*******************************update_hourF************************************
  update_hourF:
	  push r16
	  push r17
	  push r18
	  ldi YL,LOW(setAM_PM)
	  ldi YH,HIGH(setAM_PM)
	  ld r18,Y+

	  lds r16,hUnit
	  lds r17,hTenth

	  cpi r17,0x31
	  breq special_update
	  cpi r16,0x39
	  breq update_hTenth
	  inc r16
	  rjmp return_h

	  update_hTenth:
	  ldi r16,0x30
	  ;cpi r17,0x31
	  ;breq update_hour
	  ldi r17,0x31
	  rjmp return_h

	  ;update_hour:
	;  call update_hourF
	  ;ldi r17,0x30

	  special_update:
	  cpi r16,0x32
	  breq update_hTenth1
	  inc r16
	  cpi r16,0x32
	  breq change_AM_PM
	  rjmp return_h

	  change_AM_PM:
	    cpi r18,0x41
	    breq updating_AM_PM
	    ldi r18,0x41 ; change from PM to AM new day
	    call update_dayF
	    rjmp return_h
	    updating_AM_PM: ;change from AM to PM
	    ldi r18,0x50
	    rjmp return_h

	  update_hTenth1:
	  ldi r16,0x31
	  ldi r17,0x20
	  rjmp return_h

	  return_h:
	  ldi YL,LOW(setAM_PM)
	  ldi YH,HIGH(setAM_PM)
	  st Y+,r18

	  sts hUnit,r16
	  sts hTenth, r17

	  pop r18
	  pop r17
	  pop r16
	  ret

;**************************update_dayF***************************************
update_dayF:
	push r16
	push r17
	push r18
	push r19
	push r20

	lds r16,dayUnit
	lds r17, dayTenth
	lds r18, month
	mov r19,r18 ; make a copy of month to use for Modulus
	mov r20,r18

	cpi r18,8
	brlt before_august


	before_august:
	andi r19,0xFE
	tst r19
	breq first_half_31days

	first_half_not_31days:
		cpi r18,2
		breq february_update

		february_update:
			cpi r17,0x32
			breq leap_year_maybe

			cpi r16,9
			breq inc_dayTenth

			leap_year_maybe:
				andi r20,0xFC
				tst r20
				breq leap_year
				cpi r16,0x38
				inc r16
				rjmp return_day

				leap_year:
				cpi r16,0x39
				breq reset_month
				inc r16
				rjmp return_day


	first_half_31days:
		cpi r17,0x33
		breq last_2_days
		cpi r16,9
		breq inc_dayTenth
		inc r16
		rjmp return day

		inc_dayTenth:
		ldi r16,0x30
		inc r17
		rjmp return_day

		last_2_days:
		cpi r16,0x31
		breq reset_month
		inc r16


	reset_month:
	ldi r16,0x30
	ldi r16,0x30
	inc r18
	rjmp return_day

	return_day:

	sts dayUnit,r16
	sts inc_dayTenth, r17
	sts month,r18
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	ret

;
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
	ldi	r17,HIGH(1000)	; set counter to 46875
	ldi	r16,LOW(1000)
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

;Second timer
sec_timer:
	push r16
	push r17
	;grab values
	lds r17,secCountDis
	lds r16,secCount
	cpi r16,9 ;compare for value
	breq clear_second
	;increment the 2 variables
	inc r16
	inc r17

	out PORTB,r17
	;store new values
	sts secCount,r16
	sts secCountDis,r17
	pop r17
	pop r16
	ret
	clear_second:
	clr r16
	ldi r17,0x30
	out PORTB,r16
	sts secCount,r16
	sts secCountDis,r17
	pop r17
	pop r16
	ret



;
; interrupt timer 1 match compare B
;
TIM1_COMPA:
	call sec_timer
	ldi r20,2
	reti

;*******************************************************************************

Str_Hello_World:
	.db	"Hello, World", 0x0a, 0x0d, 0x00, 0x00
Str_Welcome:
	.db	"Welcome to ELEC342", 0x0a, 0x0d, 0x00, 0x00
Str_NL:
	.db	0x0a, 0x0d, 0x00, 0x00
;
;	Send the string pointed to by Z register
;
puts:
	push	r16
puts0:
	ld	r16,Z+
	tst	r16
	breq	puts1
	call	putc	; send the character in r16
	rjmp	puts0	; and loop until end of string
puts1:			; finished the string
	pop	r16
	ret
;
;	Send the character in r16
;
putc:
	push	r17
putc0:
	lds	r17,UCSR0A
	andi	r17,0x20	; check if there is space to put the character in the buffer
	breq	putc0
	sts	UDR0,r16
	pop	r17
	ret
;
;	Send the byte in r16 as a hexadecimal number
;
puth:
	push	r17
	push	r16
	lds		r16,secCountDis
	swap	r16
	call	putn
	pop	r16
	call	putn
	pop	r17
	ret
;
;	send the lower 4 bits in r16 as a hexadecimal character
;
putn:
	push	r16

	andi	r16,0x0f
	cpi	r16,10
	brlt	putn0
	subi	r16,-7
putn0:
	subi	r16,-48
	call	putc
	pop	r16
	ret

;******************************************************************************
; Send TWI start address.
; On return Z flag is set if completed correctly
; r15 and r16 destroyed
sendTWI_Start:
	ldi		r16,(1<<TWINT) | (1<<TWSTA) | (1<<TWEN)
	sts		TWCR,r16

	call	waitTWI

	lds		r16,TWSR
	andi	r16,0xf8		; mask out
	cpi		r16,0x08		; TWSR = START (0x08)
	ret
;
; Send TWI slave address. Address is in r16
; On return Z flag is set if completed correctly
; r15 and r16 destroyed
sendTWI_SLA:
	sts		TWDR,r16
	ldi		r16,(1<<TWINT) | (1<<TWEN)
	sts		TWCR,r16

	call	waitTWI

	lds		r16,TWSR
	andi	r16,0xf8		; mask out
	cpi		r16,0x18		; TWSR = SLA+W sent, ACK received (0x18)
	ret
;
; Send 8 bits of data as two 4 bit nibbles.
; The data is in r16, the lower 4 bits are in r17
; we assume the TWI operation is waiting for data to be sent.
; r15, r18 and r19 all destroyed
sendTWI_Byte:
	mov		r18,r16
	andi	r18,0xF0
	or		r18,r17
	call	sendTWI_Nibble
	mov		r18,r16
	swap	r18
	andi	r18,0xF0
	or		r18,r17
	call	sendTWI_Nibble
	ret

;
; send 4 bits of data, changing the enable bit as we send it.
; data is in r18. r15, r18 and r19 are destroyed
;
sendTWI_Nibble:
	ori		r18,0x04
	sts		TWDR,r18
	ldi		r19,(1<<TWINT) | (1<<TWEN)
	sts		TWCR,r19

	call	waitTWI			; destroys r15

	lds		r19,TWSR
	andi	r19,0xf8		; mask out
	cpi		r19,0x28		; TWSR = data sent, ACK received (0x28)
	brne	sendTWI_Nibble_exit

	andi	r18,0xFB		; set enable bit low

	sts		TWDR,r18
	ldi		r19,(1<<TWINT) | (1<<TWEN)
	sts		TWCR,r19

	call	waitTWI

	lds		r19,TWSR
	andi	r19,0xf8		; mask out
	cpi		r19,0x28		; TWSR = data sent, ACK received (0x28)
sendTWI_Nibble_exit:
	ret

;
;	Send the data pointed to by the Z register to the TWI interface.
;	r25 contains the number of bytes to send
;	r24 contains the address of the I2C controller
;	r17 contains the lower 4 bits of each nibble to send
;
SendTWI_Data:
	call	sendTWI_Start
	brne	serror

	mov		r16,r24			; use this address
	add		r16,r16			; and move over the r/w bit
	call	sendTWI_SLA
	brne	serror

	cpi		r25,0x00		; any bytes left?
	breq	sendTWI_done	; if not all done

sendTWI_loop:
	ld		r16,Z+
	call	sendTWI_Byte
	brne	serror

	dec		r25
	brne	sendTWI_loop

sendTWI_done:
serror:
;
; send stop bit and we're done
;
sendTWI_Stop:
	ldi		r16,(1<<TWINT) | (1<<TWEN) | (1<<TWSTO)		; and send stop
	sts		TWCR,r16
	ldi		r16,0
sendTWI_Delay:
	dec		r16
	brne	sendTWI_Delay
	ret
;
; Wait until the TWI (I2C) interface has sent the byte and received an ack/nak
; destroys r15
;
waitTWI:
	lds	r15,TWCR
	sbrs	r15,TWINT		; wait until transmitted
	rjmp	waitTWI
	ret
;
; Initialisation strings for the LCD panel
;

;
; LCD Position - set the write poswition in the DRAM
; r24 holds the LCD I2C address
; r25 holds the address (0-127)
; r17 holds the lower 4 bits
;
LCD_Position:
	call	sendTWI_Start
	brne	LCD_serror

	mov		r16,r24			; use this address
	add		r16,r16			; and move over the r/w bit
	call	sendTWI_SLA
	brne	LCD_serror

	mov		r16,r25
	ori		r16,0x80		; set DDRAM address command
	ldi		r17,8			; backlight
	call	sendTWI_Byte

	rjmp	sendTWI_Stop

;
; LCD Clear - Clears the LCD and places the cursor at location 0
; r24 holds the LCD I2C address
; r17 holds the lower 4 bits
;
LCD_Clear:
	call	sendTWI_Start
	brne	LCD_serror

	mov		r16,r24			; use this address
	add		r16,r16			; and move over the r/w bit
	call	sendTWI_SLA
	brne	LCD_serror

	ldi		r16,0x01		; set DDRAM address command
	ldi		r17,8			; backlight
	call	sendTWI_Byte

	rjmp	sendTWI_Stop
;
; LCD_Text - send a string to the LCD for displaying
; Z points to the string,
; r25 holds the number of characters to print,
; r24 is the address of the LCD
;
LCD_Text:
	call	sendTWI_Start
	brne	LCD_serror

	mov		r16,r24			; use this address
	add		r16,r16			; and move over the r/w bit
	call	sendTWI_SLA
	brne	LCD_serror

	cpi		r25,0x00		; any bytes left?
	breq	LCD_Text_done	; if not all done
	ldi		r17,9			; backlight + data byte
LCD_Text_loop:
	ld		r16,Z+
	call	sendTWI_Byte
	brne	LCD_serror

	dec		r25
	brne	LCD_Text_loop

LCD_Text_done:
LCD_serror:
	rjmp	sendTWI_Stop
;
; LCDSetup - setup the LCD display connected at I2C port in r16
;
LCD_Setup:
	call	sendTWI_Start						; send start bit
	breq	LCD_Setup_0
	jmp		LCD_Setup_Err
LCD_Setup_0:
	mov		r16,r24
	add		r16,r16
	call	sendTWI_SLA
	breq	LCD_Setup_1
	jmp		LCD_Setup_Err
LCD_Setup_1:
	clr		r18
	clr		r19
	call	sendTWI_Nibble
	call	sendTWI_Stop

	ldi		r18,LOW(5)
	ldi		r19,HIGH(5)
;	call	delay_ms							; wait 5 ms

;
; Send the first of three 0x30 to the display
;

	call	sendTWI_Start						; send start bit
	breq	LCD_Setup_2
	jmp		LCD_Setup_Err
LCD_Setup_2:
	mov		r16,r24
	add		r16,r16
	call	sendTWI_SLA
	breq	LCD_Setup_3
	jmp		LCD_Setup_Err
LCD_Setup_3:
	ldi		r18,0x30
	clr		r19
	call	sendTWI_Nibble
	call	sendTWI_Stop

	ldi		r18,LOW(5)
	ldi		r19,HIGH(5)
;	call	delay_ms							; wait 5 ms

;
; Send the second of three 0x30 to the display
;

	call	sendTWI_Start						; send start bit
	brne	LCD_Setup_Err
	mov		r16,r24
	add		r16,r16
	call	sendTWI_SLA
	brne	LCD_Setup_Err
	ldi		r18,0x30
	clr		r19
	call	sendTWI_Nibble
	call	sendTWI_Stop

	ldi		r18,LOW(5)
	ldi		r19,HIGH(5)
;	call	delay_ms							; wait 5 ms

;
; Send the third of three 0x30 to the display
;

	call	sendTWI_Start						; send start bit
	brne	LCD_Setup_Err
	mov		r16,r24
	add		r16,r16
	call	sendTWI_SLA
	brne	LCD_Setup_Err
	ldi		r18,0x30
	clr		r19
	call	sendTWI_Nibble
	call	sendTWI_Stop


;
; Send 0x28 to the display to reset to 4 bit mode
;

	call	sendTWI_Start						; send start bit
	brne	LCD_Setup_Err
	mov		r16,r24
	add		r16,r16
	call	sendTWI_SLA
	brne	LCD_Setup_Err
	ldi		r18,0x28
	clr		r19
	call	sendTWI_Nibble
	call	sendTWI_Stop


	ldi		ZL,LOW(setDis)
	ldi		ZH,HIGH(setDis)
	ldi		r25,2								; all 2 bytes
	ldi		r17,8								; lower 4 bits zero (Backlight on)
	call	SendTWI_Data
	ret

LCD_Setup_Err:
	rjmp	main_loop
