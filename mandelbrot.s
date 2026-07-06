; ==============================================================================
; ARM Assembly Mandelbrot Renderer
; Renders an ASCII art representation of the Mandelbrot Set.
; Designed for the VisUAL ARM Emulator.
; 
;
; Mathematical Formulation:
;   z_{n+1} = z_n^2 + c, where z_0 = 0 and c = x + i*y
;   Using 8.8 fixed-point arithmetic (scaled by 256) to represent real numbers
;   on an integer-only ARM CPU.
;
; Register Mapping:
;   R0  - Temporary register / syscall parameter
;   R1  - Current X coordinate (scaled by 256)
;   R2  - X coordinate end boundary (xend)
;   R3  - X coordinate step size (xstep)
;   R4  - Current Y coordinate (scaled by 256)
;   R5  - Y coordinate end boundary (yend)
;   R6  - Y coordinate step size (ystep)
;   R7  - Iteration counter (it)
;   R8  - Real part of z (r)
;   R9  - Imaginary part of z (i)
;   R10 - Square of real part (r2)
;   R11 - Square of imaginary part (i2)
; ==============================================================================

		B 	main

; ------------------------------------------------------------------------------
; Configuration Variables (Viewport boundaries and step sizes)
; ------------------------------------------------------------------------------
xstart		DEFW	-400		; x starting coordinate (-1.5625 * 256)
xstep   	DEFW    10			; x step interval (0.0390625 * 256)
xend    	DEFW    400			; x ending coordinate (1.5625 * 256)

ystart  	DEFW    -265		; y starting coordinate (-1.03515625 * 256)
ystep   	DEFW    10			; y step interval (0.0390625 * 256)
yend    	DEFW    265			; y ending coordinate (1.03515625 * 256)

; ------------------------------------------------------------------------------
; Initial Values for Mandelbrot Loop Variables
; ------------------------------------------------------------------------------
it    		DEFW	2048		; Maximum escape iteration limit
r    		DEFW	0			; Initial real part of z (0)
i    		DEFW	0			; Initial imaginary part of z (0)
r2   		DEFW	0			; Initial square of real part (r^2)
i2          DEFW	0			; Initial square of imaginary part (i^2)

; ------------------------------------------------------------------------------
; Character constants for ASCII output
; ------------------------------------------------------------------------------
asterisk	DEFB	"*",0
newline 	DEFB	"\n",0
space 		DEFB	" ",0

		ALIGN

; ------------------------------------------------------------------------------
; Main Program entry point
; ------------------------------------------------------------------------------
main	
		; Load outer/inner loop limits and steps into registers
		LDR R2, xend
		LDR R3, xstep
		
		LDR R4, ystart
		LDR R5, yend
		LDR R6, ystep    

		B recYCond

; Outer loop (Row iteration / Y axis)
recYLoop

		LDR R1, xstart			; Reset X coordinate at the beginning of each row

		B recXCond

; Inner loop (Column iteration / X axis)
recXLoop

				; Initialize Mandelbrot variables for this coordinate
				LDR R7, it    		
				LDR R8, r
				LDR R9, i   		
				LDR R10, r2   		
				LDR R11, i2 

; Mandelbrot calculation loop (Escape time algorithm)
mandelLoop   			         
						; tmp = r2 - i2 + x
						SUB		R0, R10, R11
						ADD		R0, R0, R1

						; i = (2 * r * i) / 256 + y
						MOV		R8, R8 LSL #1		; 2 * r
						MUL 	R8, R8, R9			; (2 * r) * i
						MOV 	R9, R8 ASR #8		; Divide by 256 (arithmetic shift right 8 bits)
						ADD		R9, R9, R4			; Add y (R4)
						
						; r = tmp
						MOV		R8, R0

						; r2 = r*r / 256
						MUL		R0, R8, R8
						MOV 	R10, R0 ASR #8

						; i2 = i*i / 256
						MUL		R0, R9, R9
						MOV 	R11, R0 ASR #8

; Loop condition checks
mandelCond						
						SUB		R7, R7, #1			; Decrement iteration limit
						CMP		R7, #0
						BEQ		exitLoop			; Exit if max iterations reached
						
						; Check divergence: (r2 + i2) > 4.0 (which is 4 * 256 = 1024)
						ADD		R0, R10, R11
						CMP		R0, #1024
						BGT		exitLoop			; Exit if sequence diverges
						
						B		mandelLoop			; Continue Mandelbrot iteration

; Decide which character to print based on divergence status
exitLoop
						CMP		R7, #0
						BNE		printAsterisk		; If it != 0, print '*' (outside the set)
						
						; Point is inside the set (it == 0), print space ' '
						ADRL 	R0, space
						SWI		3					; VisUAL system call: print string
						B		exit

printAsterisk
						ADRL 	R0, asterisk
						SWI		3					; VisUAL system call: print string

exit
				ADD		R1,	R1, R3					; Increment X coordinate (x = x + xstep)

recXCond
				CMP		R1, R2
				BLT		recXLoop					; Continue row loop if x < xend

				; Finished a row, print newline and increment Y
				ADRL 	R0, newline
				SWI		3							; VisUAL system call: print string
				ADD		R4,	R4, R6					; Increment Y coordinate (y = y + ystep)

recYCond
		
		CMP		R4, R5
		BLT		recYLoop							; Continue column loop if y < yend

		SWI	2										; VisUAL system call: Terminate program
