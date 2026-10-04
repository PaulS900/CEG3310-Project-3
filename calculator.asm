; Project 3 - Calculator
.ORIG x3000                

MAIN_LOOP
LEA R0, PROMPT1             ; R0 = address of prompt text
PUTS                        ; print string that R0 points to
JSR GETNUM                  ; call GETNUM; the number comes back in R0
ADD R6, R0, #0              

LEA R0, PROMPT_OP
PUTS                        ; print operator prompt
JSR GETOP                   ; operator character comes back in R0
ST R0, OP_SAVE              ; store operator in memory so GETNUM can't erase it

LEA R0, PROMPT2
PUTS                        ; print second number prompt
JSR GETNUM                  ; second number comes back in R0
ADD R1, R0, #0              ; R1 = second number
ADD R0, R6, #0              ; R0 = first number
LD R2, OP_SAVE              ; R2 = operator (loaded back from memory)
JSR CALC                    ; calculations, result comes back in R0
ADD R6, R0, #0              ; R6 = result 

LEA R0, RESULT_MSG
PUTS                        ; print "Result: "
ADD R0, R6, #0              ; R0 = result
JSR DISPLAY                 ; print the result as a decimal number

LD R0, NEWLINE
OUT                         ; print one character (a new line)
BR MAIN_LOOP                ; jump back to the top and repeat forever

GETNUM
ST R7, SAVE_R7              ; save return address 
GETC                        ; read one typed character into R0
OUT                         ; echo it to the screen
LD R2, NEG0                 ; R2 = -48
ADD R1, R0, R2              ; R1 = character - 48 = first digit's value

GETC                        ; read the next character (second digit OR Enter)
OUT                         ; echo it
LD R2, NEGNL                ; R2 = -10
ADD R3, R0, R2              ; R3 = character - 10 (zero if it was Enter)
BRz ONE_DIGIT               ; if zero, the number had only one digit

LD R2, NEG0
ADD R5, R0, R2              ; R5 = second digit's value
ADD R3, R1, R1              ; R3 = first digit x 2
ADD R4, R3, R3              ; R4 = first digit x 4
ADD R4, R4, R4              ; R4 = first digit x 8
ADD R0, R4, R3              ; R0 = x8 + x2 = first digit x 10
ADD R5, R0, R5              ; R5 = (first x 10) + second = finished number

GETC                        ; read and throw away the Enter key
OUT
ADD R0, R5, #0              ; put the finished number back in R0
LD R7, SAVE_R7              ; restore return address
RET                         ; return to whoever called GETNUM 

ONE_DIGIT
ADD R0, R1, #0              ; the number is just the first digit
LD R7, SAVE_R7              ; restore return address
RET                         ; return to the caller


GETOP
ST R7, SAVE_R7              ; save return address
GETOP_LOOP
GETC                        ; read a character
OUT                         ; echo it
LD R2, PLUS
ADD R3, R0, R2              ; R3 = char - '+'
BRz OP_FOUND                ; it was '+', done
LD R2, MINUS
ADD R3, R0, R2
BRz OP_FOUND                ; it was '-', done
LD R2, STAR
ADD R3, R0, R2
BRz OP_FOUND                ; it was '*', done
BR GETOP_LOOP               ; not a valid operator, try again

OP_FOUND
ADD R5, R0, #0              ; save the operator in R5
GETC                        ; read and throw away the Enter key
OUT
ADD R0, R5, #0              ; put the operator back in R0
LD R7, SAVE_R7              ; restore return address
RET                         ; return to the caller

CALC
LD R3, PLUS
ADD R4, R2, R3              ; zero if the operator is '+'
BRz ADD_OP
LD R3, MINUS
ADD R4, R2, R3              ; zero if the operator is '-'
BRz SUB_OP

; if not + or -, then *
AND R3, R3, #0              ; R3 = 0 R3 is the running total
ADD R1, R1, #0              ; does nothing to the value, just sets the condition codes
BRz MUL_DONE                ; multiplying by 0 gives 0, skip the loop
MUL_LOOP
ADD R3, R3, R0              ; total = total + first number
ADD R1, R1, #-1             ; count down the second number
BRp MUL_LOOP                ; repeat while the counter is still positive
MUL_DONE
ADD R0, R3, #0              ; R0 = the product
RET                         ; return to the caller

ADD_OP
ADD R0, R0, R1              ; result = first + second
RET

SUB_OP
NOT R1, R1                  ; flip all bits of R1
ADD R1, R1, #1              ; +1 gives the two's complement, so R1 = -second
ADD R0, R0, R1              ; result = first + (-second)
RET

DISPLAY
ST R7, SAVE_R7              ; save return address 
ADD R4, R0, #0              ; R4 = the number (DIV10 works on R4)
BRzp POSITIVE               ; if zero or positive, skip the minus sign
LEA R0, NEGATIVE
PUTS                        ; print "-"
NOT R4, R4
ADD R4, R4, #1              ; make R4 positive (negate it)

POSITIVE
LEA R5, DIGITS              ; R5 = pointer to the digit storage
AND R6, R6, #0              ; R6 = 0; counts how many digits there are

DISPLAY_LOOP
JSR DIV10                   ; R0 = R4 / 10, R3 = R4 % 10 (the last digit) bleh
STR R3, R5, #0              ; store that digit at the address in R5
ADD R5, R5, #1              ; move the pointer to the next slot
ADD R6, R6, #1              ; digit count + 1
ADD R4, R0, #0              ; continue with the quotient
BRp DISPLAY_LOOP            ; loop until the quotient hits 0 (also makes 0 print as "0")?

PRINT_LOOP                  ; digits were stored backwards, so print them in reverse
ADD R6, R6, #-1             ; one fewer digit left to print
BRn DISPLAY_DONE            
ADD R5, R5, #-1             ; step the pointer back one slot
LDR R0, R5, #0              ; R0 = the digit stored there
LD R1, ASCII0
ADD R0, R0, R1              ; add '0' to convert the value to an ASCII character
OUT                         ; print it
BR PRINT_LOOP

DISPLAY_DONE
LD R7, SAVE_R7              ; restore return address
RET                         ; return to MAIN_LOOP

DIV10
AND R0, R0, #0              ; quotient = 0
DIV_LOOP
ADD R4, R4, #-10            ; subtract 10
BRn DIV_DONE                
ADD R0, R0, #1              ; quotient + 1
BR DIV_LOOP
DIV_DONE
ADD R4, R4, #10             ; add the extra 10 back; R4 is now the remainder
ADD R3, R4, #0              ; R3 = remainder
RET                         ; return to DISPLAY

; data and prompts

PLUS       .FILL #-43       ; -'+'  
MINUS      .FILL #-45       ; -'-'
STAR       .FILL #-42       ; -'*'
NEG0       .FILL #-48       ; -'0' 
NEGNL      .FILL #-10       ; -newline (for enter key)
ASCII0     .FILL x30        ; '0'  
NEWLINE    .FILL x0A        ; newline character

PROMPT1    .STRINGZ "Enter first number (0-99): "   ; text ending in a 0 terminator
PROMPT_OP  .STRINGZ "Enter an operation (+,-,*): "
PROMPT2    .STRINGZ "Enter second number (0-99): "
RESULT_MSG .STRINGZ "Result: "
NEGATIVE   .STRINGZ "-"     ; minus sign printed for negative results

OP_SAVE    .BLKW #1         ; reserve 1 memory to hold the operator
SAVE_R7    .BLKW #1         ; reserve 1 word to hold the return address (R7)
DIGITS     .BLKW #4         ; reserve 4 words to hold the digits of the result

.END

