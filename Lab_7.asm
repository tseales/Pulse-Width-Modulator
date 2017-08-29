;************************************************************************
; Filename: Lab_7														*
;																		*
; ELEC3450 - Microprocessors											*
; Wentworth Institute of Technology										*
; Professor Bruce Decker												*
;																		*
; Student #1 Name: Takaris Seales										*
; Course Section: 03													*
; Date of Lab: <07-12-2017>												*
; Semester: Summer 2017													*
;																		*
; Function: This program uses a Pulse-Width Modulation (PWM)  			* 
; to vary the amount of energy being delivered to an LED		  		*	 	        	
;																		*
; Wiring: 																*
; One RC2 connected to LED as output for CCP1							*
; Debounceed Switched connected to all of PortD as inputs        		*			
;************************************************************************											
; A register may hold an instruction, a storage address, or any kind of data
;(such as a bit sequence or individual characters)
;BYTE-ORIENTED INSTRUCTION:	
;'f'-specifies which register is to be used by the instruction	
;'d'-designation designator: where the result of the operation is to be placed
;BIT-ORIENTED INSTRUCTION:
;'b'-bit field designator: selects # of bit affected by operation
;'f'-represents # of file in which the bit is located
;
;'W'-working register: accumulator of device. Used as an operand in conjunction with
;	 the ALU during two operand instructions														
;************************************************************************

		#include <p16f877a.inc>

TEMP_W					EQU 0X21			
TEMP_STATUS				EQU 0X22	
TEMP_D					EQU 0X23

		__CONFIG		0X373A 				;Control bits for CONFIG Register w/o WDT enabled			

		
		ORG				0X0000				;Start of memory
		GOTO 		MAIN

		ORG 			0X0004				;INTR Vector Address
PUSH										;Stores Status and W register in temp. registers

		MOVWF 		TEMP_W
		SWAPF		STATUS,W
		MOVWF 		TEMP_STATUS
		GOTO		INTR

POP											;Restores W and Status registers
	
		SWAPF		TEMP_STATUS,W
		MOVWF		STATUS
		SWAPF		TEMP_W,F
		SWAPF		TEMP_W,W				
		RETFIE

INTR										;ISR FOR Transmit and Receive
		BCF			PIR1, TMR2IF			;TMR2 to PR2 match occured
		GOTO 		POP						
				

MAIN
		CLRF 		PORTC					;Clear GPIOs to be used
		CLRF		PORTD
		BCF			INTCON, GIE				;Disable all interrupts
		BSF			STATUS, RP0				;Bank1
		MOVLW		0X00					;Set Port C as outputs for LED (CCP1 specifically)
		MOVWF		TRISC	
		MOVLW		0XFF					;Set Port D as all inputs for switches
		MOVWF		TRISD			
		BSF			PIE1, TMR2IE			;Enable Timer 2 Interrupts
		MOVLW		0X3F					;Set PR2 to 3F for TMR2 equal to PR2
		MOVWF		PR2
		BCF			STATUS, RP0				;Bank0
		CLRF		CCPR1L
		MOVLW		0x04					;TMR2 = ON, Postscale and Prescaler is 1
		MOVWF		T2CON
		MOVLW		0X0F					;Set CCP1CON to PWM Mode
		MOVWF		CCP1CON
		BSF 		INTCON, PEIE			;Enable Peripheral Interrupts
		BSF			INTCON, GIE				;Enable all interrupts
		
Bit0		;Put first LSB into CCP1CON
		MOVF		PORTD, W				;Move PortD values into Temporary D register
		MOVWF		TEMP_D
		BTFSS		TEMP_D, 0
		GOTO		Clear0
		BSF			CCP1CON, CCP1Y

		
Bit1		;Put second LSB into CCP1CON
		BTFSS		TEMP_D, 1
		GOTO		Clear1
		BSF			CCP1CON, CCP1X


Upper6		;Right Shift twice to put MSBs into CCP1L
		MOVLW		0xFC
		ANDWF		TEMP_D, F
		RRF			TEMP_D, F				;Rotate bits twice
		RRF			TEMP_D, F	
		MOVF		TEMP_D, W				;Put MSBs into W register
		MOVWF		CCPR1L					;Put MSBs into CCPR1L

		GOTO 		Bit0					;Loop

Clear0		;Clear first LSB
		BCF			CCP1CON, CCP1Y
	
		GOTO		Bit1

Clear1		;Clear second LSB
		BCF			CCP1CON, CCP1X

		GOTO		Upper6



		END
